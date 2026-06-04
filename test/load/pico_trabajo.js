import http from "k6/http";
import { check, sleep, group } from "k6";
import { Counter, Rate, Trend } from "k6/metrics";
import { extractCsrf } from "./k6_utils.js";

const BASE_URL  = "http://localhost:3000";
const EVENTO_ID = __ENV.EVENTO_ID || "20";
const ZONA_ID   = __ENV.ZONA_ID   || "33";
const CANTIDAD  = 1;

// VUs que compran usan emails distintos para no invalidarse entre sí
const VU_EMAILS = [
  "carga1@test.com", "carga2@test.com", "carga3@test.com",
  "carga4@test.com", "carga5@test.com", "carga6@test.com",
  "carga7@test.com", "carga8@test.com", "carga9@test.com",
  "carga10@test.com",
];
const PASSWORD = __ENV.USER_PASSWORD || "password123";

const navegacionOk    = new Counter("navegacion_ok");
const comprasExitosas = new Counter("compras_exitosas_pico");
const comprasError    = new Counter("compras_error_pico");
const errores5xx      = new Counter("errores_5xx_pico");
const tiempoNaveg     = new Trend("tiempo_navegacion_pico");
const tiempoCompra    = new Trend("tiempo_compra_pico");
const tasaEstabilidad = new Rate("tasa_estabilidad");

export const options = {
  stages: [
    { duration: "15s", target: 5  },
    { duration: "20s", target: 10 },
    { duration: "15s", target: 10 },
    { duration: "10s", target: 0  },
  ],
  thresholds: {
    http_req_duration:      ["p(95)<15000"],
    tiempo_navegacion_pico: ["p(95)<15000"],
    tiempo_compra_pico:     ["p(95)<15000"],
    tasa_estabilidad:       ["rate>0.50"],
    errores_5xx_pico:       ["count<150"],
  },
};

export default function () {
  // 4 de cada 5 VUs navegan; el 5° intenta comprar
  const soloNavegar = __VU % 5 !== 0;

  if (soloNavegar) {
    // Navegación
    group("Navegación home", function () {
      const t0  = Date.now();
      const res = http.get(`${BASE_URL}/`);
      tiempoNaveg.add(Date.now() - t0);

      const ok = check(res, {
        "home 200":        (r) => r.status === 200,
        "sin 5xx en home": (r) => r.status < 500,
      });
      tasaEstabilidad.add(ok);
      navegacionOk.add(ok ? 1 : 0);
      if (!ok && res.status >= 500) errores5xx.add(1);
    });

    sleep(0.5);

    group("Detalle evento", function () {
      const t0  = Date.now();
      const res = http.get(`${BASE_URL}/eventos/${EVENTO_ID}`);
      tiempoNaveg.add(Date.now() - t0);

      const ok = check(res, {
        "detalle ok":         (r) => r.status === 200 || r.status === 302,
        "sin 5xx en detalle": (r) => r.status < 500,
      });
      tasaEstabilidad.add(ok);
      if (!ok && res.status >= 500) errores5xx.add(1);
    });

  } else {
    // Login + Compra
    // k6 maneja el cookie jar automáticamente con redirects: 5
    const vuEmail = VU_EMAILS[(__VU - 1) % VU_EMAILS.length];

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
        { redirects: 5 }  // k6 guarda la cookie automáticamente
      );

      const ok = check(res, {
        "login exitoso (200)": (r) => r.status === 200,
      });
      tasaEstabilidad.add(ok);
      if (!ok) console.warn(`[VU ${__VU}] Login falló: HTTP ${res.status}`);
    });

    sleep(0.3);

    group("Compra bajo pico", function () {
      // k6 adjunta la cookie sola — no se necesita manejarla manualmente
      const newPage = http.get(`${BASE_URL}/compras/new?evento_id=${EVENTO_ID}`);
      const csrf = extractCsrf(newPage.body);

      if (!csrf) {
        tasaEstabilidad.add(false);
        if (newPage.status >= 500) errores5xx.add(1);
        return;
      }

      const t0  = Date.now();
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
      tiempoCompra.add(Date.now() - t0);

      check(res, {
        "sin 422": (r) => r.status !== 422,
        "sin 500": (r) => r.status < 500,
      });

      if (res.status === 302) {
        const loc = res.headers["Location"] ?? "";
        if (loc.includes("/pago")) {
          comprasExitosas.add(1);
        } else {
          comprasError.add(1); // cupos agotados — correcto
        }
        tasaEstabilidad.add(true);
      } else if (res.status >= 500 || res.status === 422) {
        errores5xx.add(1);
        tasaEstabilidad.add(false);
        console.warn(`[VU ${__VU}] Error ${res.status} en compra`);
      } else {
        tasaEstabilidad.add(res.status < 500);
      }
    });
  }

  sleep(soloNavegar ? 0.8 : 1.5);
}

export function handleSummary(data) {
  const m = data.metrics;
  const summary = {
    exitosas:     m.compras_exitosas_pico?.values?.count || 0,
    error_compra: m.compras_error_pico?.values?.count || 0,
    errores_5xx:  m.errores_5xx_pico?.values?.count || 0,
    p95_naveg:    m.tiempo_navegacion_pico?.values?.["p(95)"] || 0,
    p95_compra:   m.tiempo_compra_pico?.values?.["p(95)"] || 0,
  };
  console.log(`\nResumen Pico: ${summary.exitosas} Compras OK | ${summary.errores_5xx} Errores 5xx.`);
  console.log(`p95 Navegación: ${summary.p95_naveg.toFixed(0)}ms | p95 Compra: ${summary.p95_compra.toFixed(0)}ms\n`);
  return { stdout: JSON.stringify(summary, null, 2) };
}