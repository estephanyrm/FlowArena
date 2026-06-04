import http from "k6/http";
import { check, sleep, group } from "k6";
import { Counter, Rate, Trend } from "k6/metrics";
import { extractCsrf } from "./k6_utils.js";

const BASE_URL       = "http://localhost:3000";
const EVENTO_ID      = __ENV.EVENTO_ID  || "19";
const ZONA_ID        = __ENV.ZONA_ID    || "32";
const CANTIDAD       = 1;

const VU_EMAILS = [
  "carga1@test.com", "carga2@test.com", "carga3@test.com",
  "carga4@test.com", "carga5@test.com", "carga6@test.com",
  "carga7@test.com", "carga8@test.com", "carga9@test.com",
  "carga10@test.com",
];
const PASSWORD = __ENV.USER_PASSWORD || "password123";

const comprasExitosas   = new Counter("compras_exitosas");
const comprasRechazadas = new Counter("compras_rechazadas");
const erroresHttp       = new Counter("errores_http");
const tiempoPago        = new Trend("tiempo_confirmacion_pago");
const tasaExito         = new Rate("tasa_exito_compra");

export const options = {
  stages: [
    { duration: "20s", target: 3  },
    { duration: "15s", target: 10 },
    { duration: "30s", target: 10 },
    { duration: "15s", target: 0  },
  ],
  thresholds: {
    http_req_duration:          ["p(95)<2000"],
    "tiempo_confirmacion_pago": ["p(95)<3000"],
    errores_http:               ["count==0"],
    tasa_exito_compra:          ["rate>0.01"],
  },
};

export default function () {
  const vuEmail = VU_EMAILS[(__VU - 1) % VU_EMAILS.length];

  // Login
  group("Login", function () {
    const loginPage = http.get(`${BASE_URL}/users/sign_in`);
    const csrf = extractCsrf(loginPage.body);

    const res = http.post(
      `${BASE_URL}/users/sign_in`,
      {
        "user[email]":        vuEmail,
        "user[password]":     PASSWORD,
        "user[remember_me]":  "0",
        "authenticity_token": csrf,
        "commit":             "Ingresar",
      },
      { redirects: 5 }  // k6 sigue el redirect y guarda la cookie
    );

    const loginOk = check(res, {
      "login exitoso (200)": (r) => r.status === 200,
    });

    if (!loginOk) {
      console.warn(`[VU ${__VU}] Login falló: HTTP ${res.status} — verifica que '${vuEmail}' exista`);
      tasaExito.add(false);
      return;
    }

    console.log(`[VU ${__VU}] Login OK`);
  });

  sleep(0.2);

  // Compra concurrente
  group("Compra concurrente", function () {
    // k6 adjunta la cookie automáticamente a todas las requests del mismo VU
    const newPage = http.get(`${BASE_URL}/compras/new?evento_id=${EVENTO_ID}`);

    console.log(`[VU ${__VU}] GET /compras/new => ${newPage.status}`);

    const csrf = extractCsrf(newPage.body);

    if (!csrf) {
      console.warn(`[VU ${__VU}] Sin CSRF (status ${newPage.status}) — posible redirect a login`);
      tasaExito.add(false);
      if (newPage.status >= 500) erroresHttp.add(1);
      return;
    }

    console.log(`[VU ${__VU}] CSRF OK`);

    const res = http.post(
      `${BASE_URL}/compras`,
      {
        "authenticity_token": csrf,
        "evento_id":          String(EVENTO_ID),
        "zona_id":            String(ZONA_ID),
        "cantidad":           String(CANTIDAD),
        "habeas_data":        "1",
      },
      { redirects: 0 }
    );

    console.log(`[VU ${__VU}] POST /compras => ${res.status} | Location: ${res.headers["Location"] || "N/A"}`);

    check(res, {
      "sin 422": (r) => r.status !== 422,
      "sin 500": (r) => r.status < 500,
    });

    if (res.status === 302) {
      const location = res.headers["Location"] ?? "";

      if (location.includes("/pago")) {
        comprasExitosas.add(1);
        tasaExito.add(true);

        const pagoPage = http.get(
          location.startsWith("http") ? location : `${BASE_URL}${location}`
        );
        const csrfPago = extractCsrf(pagoPage.body);
        const compraId = location.match(/\/compras\/(\d+)\//)?.[1];

        if (compraId && csrfPago) {
          const t0 = Date.now();
          const pagoRes = http.post(
            `${BASE_URL}/compras/${compraId}/confirmar_pago`,
            { "authenticity_token": csrfPago, "metodo_pago": "efecty" },
            { redirects: 5 }
          );
          tiempoPago.add(Date.now() - t0);
          check(pagoRes, { "pago confirmado (200)": (r) => r.status === 200 });
        }

      } else {
        // Cupos agotados — comportamiento correcto RF-03
        comprasRechazadas.add(1);
        tasaExito.add(false);
        console.log(`[VU ${__VU}] Cupos agotados (correcto)`);
      }

    } else if (res.status >= 500 || res.status === 422) {
      erroresHttp.add(1);
      tasaExito.add(false);
      console.warn(`[VU ${__VU}] Error ${res.status}`);
    } else {
      tasaExito.add(false);
      console.warn(`[VU ${__VU}] Status inesperado: ${res.status}`);
    }
  });

  sleep(1);
}

export function teardown() {
  const res = http.del(
    `${BASE_URL}/load_test/cleanup`,
    JSON.stringify({ prefix: "k6_" }),
    { headers: { "Content-Type": "application/json", "X-Load-Test-Token": __ENV.LOAD_TEST_TOKEN || "dev-cleanup-token" } }
  );
  if (res.status === 200) {
    console.log(`Teardown OK: ${JSON.parse(res.body).deleted ?? "?"} compras eliminadas`);
  }
}

export function handleSummary(data) {
  const m = data.metrics;
  const summary = {
    exitosas:    m.compras_exitosas?.values?.count || 0,
    rechazadas:  m.compras_rechazadas?.values?.count || 0,
    errores:     m.errores_http?.values?.count || 0,
    p95_general: m.http_req_duration?.values?.["p(95)"] || 0,
    p95_pago:    m.tiempo_confirmacion_pago?.values?.["p(95)"] || 0,
  };
  console.log(`\nResumen: ${summary.exitosas} OK, ${summary.rechazadas} Rechazadas (RF-03: cupos agotados = correcto), ${summary.errores} Errores HTTP.`);
  console.log(`p95 General: ${summary.p95_general.toFixed(0)}ms | p95 Pago: ${summary.p95_pago.toFixed(0)}ms\n`);
  return { stdout: JSON.stringify(summary, null, 2) };
}