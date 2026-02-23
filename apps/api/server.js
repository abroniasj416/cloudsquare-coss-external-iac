const http = require("http");

const PORT = 8080;

const certificates = [
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

const server = http.createServer((req, res) => {
  if (req.method === "GET" && req.url === "/api/health") {
    res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("ok");
    return;
  }

  if (req.method === "GET" && req.url === "/api/certificates") {
    const body = JSON.stringify(certificates);
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    res.end(body);
    return;
  }

  res.writeHead(404, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify({ message: "not found" }));
});

server.listen(PORT, () => {
  console.log(`api listening on ${PORT}`);
});