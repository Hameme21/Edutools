const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const { connectDB } = require('./db');
const apiRoutes = require('./routes/api');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for web client, mobile apps, and developer portals
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
}));

// Request body parsers
app.use(express.json({ limit: '15mb' }));
app.use(express.urlencoded({ extended: true, limit: '15mb' }));

// Serve static uploaded files safely
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express.static(uploadsDir));

// Backend status dashboard — always shown at root
const FRONTEND_URL = process.env.FRONTEND_URL || 'https://edutools-uiu.vercel.app';
const RENDER_URL = process.env.RENDER_EXTERNAL_URL || `http://localhost:${PORT}`;

app.get('/', async (req, res) => {
  let frontendStatus = 'UNKNOWN';
  let frontendLatency = null;
  try {
    const start = Date.now();
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 5000);
    const resp = await fetch(FRONTEND_URL, { method: 'HEAD', signal: ctrl.signal });
    clearTimeout(timer);
    frontendLatency = Date.now() - start;
    frontendStatus = resp.ok ? 'REACHABLE' : `HTTP ${resp.status}`;
  } catch (e) {
    frontendStatus = `UNREACHABLE (${e.code || e.message})`;
  }

  let smtpStatus = 'UNKNOWN';
  try {
    const authService = require('./services/auth_service');
    await authService.transporter.verify();
    smtpStatus = 'CONNECTED';
  } catch (e) {
    smtpStatus = `FAILED (${e.code || e.message})`;
  }

  const uptimeSeconds = Math.floor(process.uptime());
  const uptimeStr = `${Math.floor(uptimeSeconds / 3600)}h ${Math.floor((uptimeSeconds % 3600) / 60)}m ${uptimeSeconds % 60}s`;

  if (req.accepts('html') && (req.headers['sec-fetch-dest'] === 'document' || req.headers['user-agent']?.includes('Mozilla'))) {
    const smtpDot = smtpStatus === 'CONNECTED' ? '#4ade80' : '#f87171';
    const frontendDot = frontendStatus === 'REACHABLE' ? '#4ade80' : '#f87171';
    return res.send(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edutools — API Server</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:#0a0a0a;color:#fafafa;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:24px}
  .container{max-width:480px;width:100%}
  .hero{text-align:center;margin-bottom:32px}
  .logo{width:56px;height:56px;background:linear-gradient(135deg,#f97316,#fb923c);border-radius:14px;display:inline-flex;align-items:center;justify-content:center;font-size:28px;margin-bottom:16px;box-shadow:0 8px 32px rgba(249,115,22,0.25)}
  h1{font-size:24px;font-weight:700;letter-spacing:-0.5px}
  h1 span{color:#f97316}
  .badge{display:inline-block;background:#14532d;color:#4ade80;font-size:11px;font-weight:600;padding:3px 10px;border-radius:20px;margin-top:8px;letter-spacing:0.5px;text-transform:uppercase}
  .visit{display:block;margin:28px auto 0;background:linear-gradient(135deg,#f97316,#ea580c);color:#fff;font-size:15px;font-weight:600;padding:14px 32px;border:none;border-radius:12px;cursor:pointer;text-decoration:none;text-align:center;transition:transform 0.15s,box-shadow 0.15s;box-shadow:0 4px 20px rgba(249,115,22,0.3)}
  .visit:hover{transform:translateY(-2px);box-shadow:0 8px 30px rgba(249,115,22,0.4)}
  .visit small{display:block;font-size:11px;font-weight:400;opacity:0.85;margin-top:2px}
  .panel{background:#141414;border:1px solid #262626;border-radius:14px;padding:20px;margin-top:28px}
  .panel-title{font-size:12px;color:#737373;text-transform:uppercase;letter-spacing:1px;font-weight:600;margin-bottom:14px}
  .status-row{display:flex;align-items:center;justify-content:space-between;padding:9px 0;border-bottom:1px solid #1e1e1e}
  .status-row:last-child{border-bottom:none}
  .status-label{display:flex;align-items:center;gap:8px;font-size:13px;color:#a3a3a3}
  .dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
  .status-val{font-size:13px;font-weight:500;color:#e5e5e5}
  .status-val a{color:#38bdf8;text-decoration:none}
  .status-val a:hover{text-decoration:underline}
  .latency{font-size:11px;color:#525252;margin-left:4px}
  .endpoints{margin-top:20px}
  .endpoints .panel-title{margin-bottom:10px}
  .ep-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
  .ep{background:#1a1a1a;border:1px solid #262626;border-radius:8px;padding:10px 12px;text-decoration:none;transition:border-color 0.15s}
  .ep:hover{border-color:#404040}
  .ep-name{font-size:12px;font-weight:600;color:#e5e5e5}
  .ep-path{font-size:11px;color:#525252;margin-top:2px}
  .footer{text-align:center;margin-top:24px;font-size:11px;color:#404040}
</style>
</head>
<body>
<div class="container">
  <div class="hero">
    <div class="logo">E</div>
    <h1>Edutools <span>API</span></h1>
    <div class="badge">Backend Server Online</div>
    <a class="visit" href="${FRONTEND_URL}" target="_blank">
      Open Edutools Website
      <small>${FRONTEND_URL.replace('https://', '')}</small>
    </a>
  </div>

  <div class="panel">
    <div class="panel-title">System Status</div>
    <div class="status-row">
      <span class="status-label"><span class="dot" style="background:#4ade80"></span>Backend API</span>
      <span class="status-val">Running</span>
    </div>
    <div class="status-row">
      <span class="status-label"><span class="dot" style="background:${frontendDot}"></span>Frontend (Vercel)</span>
      <span class="status-val">${frontendStatus}${frontendLatency !== null ? `<span class="latency">${frontendLatency}ms</span>` : ''}</span>
    </div>
    <div class="status-row">
      <span class="status-label"><span class="dot" style="background:${smtpDot}"></span>Email (SMTP)</span>
      <span class="status-val">${smtpStatus}</span>
    </div>
    <div class="status-row">
      <span class="status-label"><span class="dot" style="background:#4ade80"></span>Uptime</span>
      <span class="status-val">${uptimeStr}</span>
    </div>
  </div>

  <div class="panel endpoints">
    <div class="panel-title">API Endpoints</div>
    <div class="ep-grid">
      <a class="ep" href="/api/health"><div class="ep-name">Health Check</div><div class="ep-path">GET /api/health</div></a>
      <a class="ep" href="/app"><div class="ep-name">Web App</div><div class="ep-path">GET /app</div></a>
      <a class="ep" href="/api/auth/request-otp"><div class="ep-name">Request OTP</div><div class="ep-path">POST /api/auth</div></a>
      <a class="ep" href="/api/auth/verify-otp"><div class="ep-name">Verify OTP</div><div class="ep-path">POST /api/auth</div></a>
    </div>
  </div>

  <p class="footer">Edutools API Server &middot; United International University &middot; ${new Date().toISOString().split('T')[0]}</p>
</div>
</body>
</html>`);
  }

  res.json({
    service: 'Edutools Academic Backend API',
    status: 'ONLINE',
    uptime: uptimeStr,
    frontend: { url: FRONTEND_URL, status: frontendStatus, latencyMs: frontendLatency },
    smtp: smtpStatus,
    endpoints: {
      webApp: '/app',
      health: '/api/health',
      requestOtp: 'POST /api/auth/request-otp',
      verifyOtp: 'POST /api/auth/verify-otp',
      loginPassword: 'POST /api/auth/login-password',
    },
  });
});

// Serve Web App at /app only (not at root — root is the dashboard above)
const localPublicDir = path.join(__dirname, 'public');
const docsDir = path.join(__dirname, '..', 'docs');
const webAppDir = path.join(__dirname, '..', 'web_app');
let staticWebDir = localPublicDir;
if (fs.existsSync(path.join(localPublicDir, 'index.html'))) {
  staticWebDir = localPublicDir;
} else if (fs.existsSync(path.join(docsDir, 'index.html'))) {
  staticWebDir = docsDir;
} else if (fs.existsSync(path.join(webAppDir, 'index.html'))) {
  staticWebDir = webAppDir;
}

if (fs.existsSync(staticWebDir)) {
  app.use(express.static(staticWebDir, { index: false }));
  app.get('/app', (req, res) => {
    res.sendFile(path.join(staticWebDir, 'index.html'));
  });
}

// Mount REST API endpoints
app.use('/api', apiRoutes);

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[SERVER ERROR]:', err);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Internal Server Error',
  });
});

if (require.main === module) {
  const authService = require('./services/auth_service');
  connectDB().then(() => {
    authService.verifySMTP();
    app.listen(PORT, () => {
      console.log(`\n🎓 ========================================================`);
      console.log(`🚀 Edutools Full-Stack Server listening on http://localhost:${PORT}`);
      console.log(`✅ University Email Auth (.edu, .ac.bd) ready with 5-min OTP`);
      console.log(`✅ Password Authentication enabled`);
      console.log(`✅ File Uploader active (10MB max, .ics, .csv, .json, .pdf)`);
      console.log(`✅ Calendar Sync Status Engine listening on /api/calendar/sync-status`);
      console.log(`✅ MongoDB Cloud Sync for persistent schedule storage`);
      console.log(`========================================================\n`);
    });
  });
}

module.exports = app;
