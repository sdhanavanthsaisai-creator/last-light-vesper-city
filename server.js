const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = Number(process.env.PORT) || 3000;
const HOST = process.env.HOST || "0.0.0.0";
const PUBLIC_DIR = path.join(__dirname, "public");
const ROBLOX_DIR = path.join(__dirname, "roblox", "src");

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".luau": "text/plain; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
};

function collectLuauFiles(dir, baseDir = dir, list = []) {
  if (!fs.existsSync(dir)) return list;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectLuauFiles(fullPath, baseDir, list);
    } else if (entry.name.endsWith(".luau")) {
      const relPath = path.relative(baseDir, fullPath).replace(/\\/g, "/");
      const content = fs.readFileSync(fullPath, "utf8");
      list.push({
        path: `roblox/src/${relPath}`,
        studioLocation: relPath.replace(/\.luau$/, ""),
        name: entry.name,
        lines: content.split("\n").length,
        content,
      });
    }
  }
  return list;
}

const server = http.createServer((req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  const pathname = decodeURIComponent(parsedUrl.pathname);

  if (pathname === "/api/luau-files") {
    const files = collectLuauFiles(ROBLOX_DIR);
    const projectJsonPath = path.join(__dirname, "default.project.json");
    const rojoConfig = fs.existsSync(projectJsonPath)
      ? fs.readFileSync(projectJsonPath, "utf8")
      : "{}";
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    res.end(JSON.stringify({ files, rojoConfig }));
    return;
  }

  if (pathname === "/api/health") {
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    res.end(
      JSON.stringify({
        status: "ok",
        project: "LAST LIGHT: The City That Forgot You — Operation BLACKOUT",
        milestone: "Milestone 1 Vertical Slice",
      })
    );
    return;
  }

  let filePath = path.join(PUBLIC_DIR, pathname === "/" ? "index.html" : pathname);
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    filePath = path.join(filePath, "index.html");
  }

  if (!fs.existsSync(filePath)) {
    filePath = path.join(PUBLIC_DIR, "index.html");
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || "application/octet-stream";

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(500);
      res.end("Internal Server Error");
      return;
    }
    res.writeHead(200, { "Content-Type": contentType });
    res.end(content);
  });
});

server.listen(PORT, HOST, () => {
  console.log(`[LAST LIGHT] 3D Web Experience & Roblox Hub running on http://${HOST}:${PORT}`);
});
