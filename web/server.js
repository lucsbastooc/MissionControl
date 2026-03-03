const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 3000;
const BOARD_DIR = path.join(__dirname, '..');

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, PUT, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (pathname === '/board-state.json') {
    const filePath = path.join(BOARD_DIR, 'board-state.json');
    
    if (req.method === 'GET') {
      fs.readFile(filePath, (err, data) => {
        if (err) {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Not found' }));
          return;
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(data);
      });
      return;
    }
    
    if (req.method === 'PUT') {
      let body = '';
      req.on('data', chunk => body += chunk);
      req.on('end', () => {
        fs.writeFile(filePath, body, 'utf8', (err) => {
          if (err) {
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: err.message }));
            return;
          }
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ success: true }));
        });
      });
      return;
    }
  }

  let filePath = path.join(__dirname, pathname === '/' ? 'index.html' : pathname);
  
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    
    const ext = path.extname(filePath);
    const contentTypes = {
      '.html': 'text/html',
      '.js': 'application/javascript',
      '.css': 'text/css'
    };
    
    res.writeHead(200, { 'Content-Type': contentTypes[ext] || 'text/plain' });
    res.end(data);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Mission Control: http://localhost:${PORT}`);
});
