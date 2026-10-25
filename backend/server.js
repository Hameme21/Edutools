const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

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

// Root greeting & diagnostics info (or Web App for browser users)
app.get('/', (req, res) => {
  if (req.accepts('html') && !req.xhr && (req.headers['sec-fetch-dest'] === 'document' || req.headers['user-agent']?.includes('Mozilla'))) {
    const indexPath = path.join(staticWebDir, 'index.html');
    if (fs.existsSync(indexPath)) {
      return res.sendFile(indexPath);
    }
  }
  res.json({
    service: 'EduTools Academic Backend API',
    status: 'ONLINE',
    webApp: 'http://localhost:' + PORT + '/app',
    documentation: {
      auth: {
        requestOtp: 'POST /api/auth/request-otp (body: { email })',
        verifyOtp: 'POST /api/auth/verify-otp (body: { email, otp })',
        profile: 'GET /api/auth/me (header: Bearer token)',
      },
      upload: {
        uploadFile: 'POST /api/upload (multipart form-data with file; max 10MB)',
      },
      calendar: {
        sync: 'POST /api/calendar/sync (body: { rawSchedule, events })',
        syncStatus: 'GET /api/calendar/sync-status?email=student@university.edu',
      },
      health: 'GET /api/health',
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
  app.listen(PORT, () => {
    console.log(`\n🎓 ========================================================`);
    console.log(`🚀 EduCal Full-Stack Server listening on http://localhost:${PORT}`);
    console.log(`✅ University Email Auth (.edu, .ac.bd) ready with 5-min OTP`);
    console.log(`✅ File Uploader active (10MB max, .ics, .csv, .json, .pdf)`);
    console.log(`✅ Calendar Sync Status Engine listening on /api/calendar/sync-status`);
    console.log(`========================================================\n`);
  });
}

module.exports = app;
