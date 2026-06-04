import http from "k6/http";

export function uniquePrefix() {
  return `k6_${__VU}_${Date.now()}`;
}

export function uniqueEmail() {
  return `k6_${__VU}_${Date.now()}@loadtest.invalid`;
}

export function uniqueOrdenRef() {
  return `FA-LOAD-${__VU}-${Date.now()}`;
}

export function extractCsrf(responseBody) {
  if (!responseBody) return "";

  const inputBlockMatch = responseBody.match(
    /<input[^>]*authenticity_token[^>]*>/
  );
  if (inputBlockMatch) {
    const valueMatch = inputBlockMatch[0].match(/value="([^"]+)"/);
    if (valueMatch) return valueMatch[1];
  }

  const metaBlockMatch = responseBody.match(
    /<meta[^>]*csrf-token[^>]*>/
  );
  if (metaBlockMatch) {
    const contentMatch = metaBlockMatch[0].match(/content="([^"]+)"/);
    if (contentMatch) return contentMatch[1];
  }

  return "";
}

export function extractSession(response, previousValue = "") {
  const viaCookies = response.cookies?._flowarena_session?.[0]?.value;
  if (viaCookies) return viaCookies;
  const setCookie = response.headers?.["Set-Cookie"] ?? "";
  const match = setCookie.match(/_flowarena_session=([^;]+)/);
  if (match?.[1]) return match[1];

  return previousValue;
}

export const HEADERS_FORM = {
  "Content-Type": "application/x-www-form-urlencoded",
  Accept: "text/html,application/xhtml+xml",
};

export function headersWithSession(sessionCookie) {
  return {
    ...HEADERS_FORM,
    Cookie: `_flowarena_session=${sessionCookie}`,
  };
}

export function loginUser(baseUrl, email, password) {
  const loginPage = http.get(`${baseUrl}/users/sign_in`);
  const csrf = extractCsrf(loginPage.body);
  let session = extractSession(loginPage);

  const res = http.post(
    `${baseUrl}/users/sign_in`,
    {
      "user[email]":        email,
      "user[password]":     password,
      "user[remember_me]":  "0",
      "authenticity_token": csrf,
      "commit":             "Ingresar",
    },
    {
      headers:   { ...HEADERS_FORM, Cookie: `_flowarena_session=${session}` },
      redirects: 5,
    }
  );

  return extractSession(res, session);
}

export function loginAdmin(baseUrl, email, password) {
  const loginPage = http.get(`${baseUrl}/admins/sign_in`);
  const csrf = extractCsrf(loginPage.body);
  let session = extractSession(loginPage);

  const res = http.post(
    `${baseUrl}/admins/sign_in`,
    {
      "admin[email]":       email,
      "admin[password]":    password,
      "authenticity_token": csrf,
      "commit":             "Ingresar",
    },
    {
      headers:   { ...HEADERS_FORM, Cookie: `_flowarena_session=${session}` },
      redirects: 5,
    }
  );

  return extractSession(res, session);
}