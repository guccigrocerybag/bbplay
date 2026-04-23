// Simple dev server with proxy for CORS
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const path = require('path');

const app = express();
const PORT = 3000;

// Serve static files from build/web directory (where Flutter web files are)
app.use(express.static(path.join(__dirname, '..', 'build', 'web')));

// Proxy API requests to avoid CORS
const apiProxy = createProxyMiddleware({
  target: 'https://vibe.blackbearsplay.ru',
  changeOrigin: true,
  secure: true,
  logLevel: 'debug',
  pathRewrite: {
    '^/api': '/api', // Keep as is
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying: ${req.method} ${req.url} -> ${proxyReq.path}`);
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err);
    res.status(500).send('Proxy error');
  }
});

// Apply proxy to all API routes
app.use('/api', apiProxy);
app.use('/login', apiProxy);
app.use('/cafes', apiProxy);
app.use('/struct-rooms-icafe', apiProxy);
app.use('/available-pcs-for-booking', apiProxy);
app.use('/booking', apiProxy);
app.use('/all-books-cafes', apiProxy);
app.use('/request-sms', apiProxy);
app.use('/verify', apiProxy);
app.use('/topup', apiProxy);
app.use('/cancel', apiProxy);

// Serve index.html for all other routes (for Flutter web routing)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'build', 'web', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Dev server running at http://localhost:${PORT}`);
  console.log('Proxying API requests to https://vibe.blackbearsplay.ru');
  console.log('Open http://localhost:3000 in your browser');
});