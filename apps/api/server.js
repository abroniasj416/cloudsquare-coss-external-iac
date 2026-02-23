const http = require("http");

const PORT = 8080;
const COSS_API_BASE_URL = (process.env.COSS_API_BASE_URL || "").trim().replace(/\/$/, "");

const dummyCertificates = [
  {
    serialNumber: "0001-0002",
    lectureId: 101,
    userId: 2001,
    issuedAt: "2026-01-01T10:00:00Z"
  },
  {
    serialNumber: "0003-0010",
    lectureId: 102,
    userId: 2002,
    issuedAt: "2026-01-02T11:30:00Z"
  }
];

function sendJson(res, statusCode, body) {
  res.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

async function fetchCertificatesFromCoss() {
  const endpoint = `${COSS_API_BASE_URL}/api/certificates`;
  const response = await fetch(endpoint, { method: "GET" });
  if (!response.ok) {
    throw new Error(`upstream status ${response.status}`);
  }
  return response.json();
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === "GET" && req.url === "/api/health") {
      res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("ok");
      return;
    }

    if (req.method === "GET" && req.url === "/api/certificates") {
      if (!COSS_API_BASE_URL) {
        sendJson(res, 200, dummyCertificates);
        return;
      }

      const data = await fetchCertificatesFromCoss();
      sendJson(res, 200, data);
      return;
    }

    sendJson(res, 404, { message: "not found" });
  } catch (error) {
    sendJson(res, 502, {
      message: "upstream request failed",
      detail: error.message,
      cossApiBaseUrl: COSS_API_BASE_URL || ""
    });
  }
});

server.listen(PORT, () => {
  console.log(`api listening on ${PORT}`);
});