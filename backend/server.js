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

// Serve All-in-One Web App for browser users (public/ folder, docs/ directory, or web_app/)
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
  app.use(express.static(staticWebDir));
  app.get('/app', (req, res) => {
    res.sendFile(path.join(staticWebDir, 'index.html'));
  });
}

// Mount REST API endpoints
app.use('/api', apiRoutes);

// Backend status dashboard — always shown at root instead of the frontend
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
    return res.send(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edutools Backend — Status</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0f172a;color:#e2e8f0;min-height:100vh;display:flex;align-items:center;justify-content:center}
  .card{background:#1e293b;border:1px solid #334155;border-radius:16px;padding:32px;max-width:520px;width:90%}
  h1{font-size:22px;color:#f97316;margin-bottom:4px;letter-spacing:-0.5px}
  .sub{font-size:13px;color:#64748b;margin-bottom:24px}
  .row{display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-bottom:1px solid #334155}
  .row:last-child{border-bottom:none}
  .label{font-size:14px;color:#94a3b8}
  .val{font-size:14px;font-weight:600}
  .ok{color:#4ade80} .warn{color:#facc15} .err{color:#f87171}
  .latency{font-size:12px;color:#64748b;margin-left:6px}
  a{color:#38bdf8;text-decoration:none}
  a:hover{text-decoration:underline}
  .footer{margin-top:20px;text-align:center;font-size:12px;color:#475569}
</style>
</head>
<body>
<div class="card">
  <h1>Edutools Backend</h1>
  <p class="sub">Node.js API Server — United International University</p>
  <div class="row"><span class="label">Backend</span><span class="val ok">ONLINE</span></div>
  <div class="row"><span class="label">Render URL</span><span class="val"><a href="${RENDER_URL}">${RENDER_URL}</a></span></div>
  <div class="row"><span class="label">Frontend (Vercel)</span><span class="val ${frontendStatus === 'REACHABLE' ? 'ok' : 'err'}">${frontendStatus}${frontendLatency !== null ? `<span class="latency">${frontendLatency}ms</span>` : ''}</span></div>
  <div class="row"><span class="label">Frontend URL</span><span class="val"><a href="${FRONTEND_URL}" target="_blank">${FRONTEND_URL}</a></span></div>
  <div class="row"><span class="label">Gmail SMTP</span><span class="val ${smtpStatus === 'CONNECTED' ? 'ok' : 'err'}">${smtpStatus}</span></div>
  <div class="row"><span class="label">Uptime</span><span class="val">${uptimeStr}</span></div>
  <div class="row"><span class="label">Health API</span><span class="val"><a href="/api/health">/api/health</a></span></div>
  <div class="row"><span class="label">Web App</span><span class="val"><a href="/app">/app</a></span></div>
  <p class="footer">Checked at ${new Date().toISOString()}</p>
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
