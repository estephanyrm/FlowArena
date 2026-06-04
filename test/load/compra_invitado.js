import http from "k6/http";
import { check, sleep, group } from "k6";
import { Counter, Trend, Rate } from "k6/metrics";
import {
  uniqueEmail,
  extractCsrf,
  extractSession,
  headersWithSession,
  HEADERS_FORM,
} from "./k6_utils.js";

const BASE_URL  = "http://localhost:3000";
const EVENTO_ID = __ENV.EVENTO_ID || "18";
const ZONA_ID   = __ENV.ZONA_ID   || "31";

const boletosEmitidos  = new Counter("boletos_emitidos");
const erroresHttp      = new Counter("errores_http");
const tiempoFlujoTotal = new Trend("tiempo_flujo_completo");
const tiempoPago       = new Trend("tiempo_confirmar_pago");
const flujoCompletado  = new Rate("tasa_flujo_completado");
const qrPresente       = new Rate("tasa_qr_presente");
const datosBoletoOk    = new Rate("tasa_datos_boleto_completos");

export const options = {
  stages: [
    { duration: "30s", target: 5  },
    { duration: "30s", target: 10 },
    { duration: "60s", target: 10 },
    { duration: "20s", target: 0  },
  ],
  thresholds: {
    "tiempo_confirmar_pago":        ["p(95)<3000"],
    "tiempo_flujo_completo":        ["p(95)<10000"],
    "tasa_flujo_completado":        ["rate>0.8"],
    "tasa_qr_presente":             ["rate>0.9"],
    "tasa_datos_boleto_completos":  ["rate>0.9"],
    errores_http:                   ["count==0"],
  },
};

export default function () {
  const email = uniqueEmail();
  const inicioFlujo = Date.now();
  let csrfToken = "";
  let sessionCookie = "";

  group("Selección de zona", function () {
    const res = http.get(`${BASE_URL}/compras/new?evento_id=${EVENTO_ID}`);
    check(res, { "status 200": (r) => r.status === 200 });
    csrfToken = extractCsrf(res.body);
    sessionCookie = extractSession(res);
  });

  sleep(0.5);

  let compraId = null;
  group("Creación compra", function () {
    const res = http.post(`${BASE_URL}/compras`,
      {
        "authenticity_token": csrfToken,
        "evento_id":          String(EVENTO_ID),
        "zona_id":            String(ZONA_ID),
        "cantidad":           "1",
        "email_invitado":     email,
        "habeas_data":        "1",
        "commit":             "Continuar",
      },
      {
        headers:   headersWithSession(sessionCookie),
        redirects: 0,
      }
    );

    const location = res.headers["Location"] ?? "";
    if (res.status === 302 && location.includes("/pago")) {
      compraId = location.match(/\/compras\/(\d+)\//)?.[1];
      sessionCookie = extractSession(res, sessionCookie);
    } else if (res.status >= 500) {
      erroresHttp.add(1);
    }
  });

  if (!compraId) return;

  sleep(0.3);

  let csrfPago = "";
  group("Página de pago", function () {
    const res = http.get(`${BASE_URL}/compras/${compraId}/pago`,
      { headers: { Cookie: `_flowarena_session=${sessionCookie}` } }
    );
    csrfPago = extractCsrf(res.body);
    sessionCookie = extractSession(res, sessionCookie);
  });

  sleep(0.5);

  group("Confirmación pago", function () {
    const t0 = Date.now();
    const res = http.post(`${BASE_URL}/compras/${compraId}/confirmar_pago`,
      {
        "authenticity_token": csrfPago,
        "metodo_pago":        "efecty",
      },
      {
        headers:   headersWithSession(sessionCookie),
        redirects: 5,
      }
    );

    tiempoPago.add(Date.now() - t0);

    const pagoOk = check(res, { "pago exitoso": (r) => r.status === 200 });
    const datosOk = check(res, { "datos ok": (r) => r.body.includes("Evento") || r.body.includes("General") });
    const qrOk = check(res, { "qr presente": (r) => r.body.includes("qr") || r.body.includes("QR") });

    if (pagoOk) {
      boletosEmitidos.add(1);
      flujoCompletado.add(true);
    } else {
      flujoCompletado.add(false);
      if (res.status >= 500) erroresHttp.add(1);
    }

    qrPresente.add(qrOk ? 1 : 0);
    datosBoletoOk.add(datosOk ? 1 : 0);
  });

  tiempoFlujoTotal.add(Date.now() - inicioFlujo);
  sleep(1);
}

export function teardown() {
  http.del(`${BASE_URL}/load_test/cleanup`,
    JSON.stringify({ prefix: "k6_" }),
    {
      headers: {
        "Content-Type":      "application/json",
        "X-Load-Test-Token": __ENV.LOAD_TEST_TOKEN || "dev-cleanup-token",
      },
    }
  );
}

export function handleSummary(data) {
  const { boletos_emitidos, errores_http } = data.metrics;
  const { tiempo_flujo_completo, tiempo_confirmar_pago } = data.metrics;

  const summary = {
    boletos: boletos_emitidos?.values?.count || 0,
    errores: errores_http?.values?.count || 0,
    p95_flujo: tiempo_flujo_completo?.values?.["p(95)"] || 0,
    p95_pago: tiempo_confirmar_pago?.values?.["p(95)"] || 0
  };

  console.log(`\nResumen: ${summary.boletos} Boletos emitidos | ${summary.errores} Errores HTTP.`);
  console.log(`p95 Flujo total: ${summary.p95_flujo.toFixed(0)}ms | p95 Pago: ${summary.p95_pago.toFixed(0)}ms\n`);

  return { stdout: JSON.stringify(summary, null, 2) };
}