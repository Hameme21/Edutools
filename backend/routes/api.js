const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const authService = require('../services/auth_service');
const calendarSyncService = require('../services/calendar_sync_service');

const router = express.Router();

// Setup Multer upload directory with 10MB file limit
const UPLOAD_DIR = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (req, file, cb) => {
    const uniquePrefix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniquePrefix + '-' + file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_'));
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10 MB limit enforcement
  },
  fileFilter: (req, file, cb) => {
    const allowedExtensions = ['.ics', '.csv', '.json', '.txt', '.pdf'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (!allowedExtensions.includes(ext)) {
      return cb(new Error(`Unsupported file format "${ext}". Please upload .ics, .csv, .json, .txt, or .pdf files.`));
    }
    cb(null, true);
  },
});

// Middleware for optional or required session verification
function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'Authorization token required.' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const student = authService.verifySessionToken(token);
    req.student = student;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, error: err.message });
  }
}

function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      req.student = authService.verifySessionToken(token);
    } catch (_) {}
  }
  next();
}

// ===================== 1. AUTHENTICATION ENDPOINTS =====================

/**
 * GET /api/auth/check-student?email=...
 * Checks whether a student email is already registered in the system
 */
router.get('/auth/check-student', (req, res) => {
  const email = req.query.email?.trim().toLowerCase();
  if (!email) {
    return res.status(400).json({ success: false, error: 'Email parameter is required.' });
  }
  const isRegistered = authService.isEmailRegistered(email);
  const student = authService.studentStore.get(email);
  res.json({
    success: true,
    email,
    isRegistered,
    hasPassword: authService.checkHasPassword(email),
    student: student ? {
      fullName: student.fullName,
      studentId: student.studentId,
      department: student.department,
      semester: student.semester,
    } : null,
  });
});

/**
 * POST /api/auth/request-otp
 * Validates .edu university email, creates 6-digit OTP (5m TTL), and sends via email
 */
router.post('/auth/request-otp', async (req, res) => {
  try {
    const { email, fullName, studentId, department, semester, isRegistration, password, deviceId } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, error: 'Email address is required.' });
    }

    const result = await authService.requestOtp(email, {
      fullName,
      studentId,
      department,
      semester,
      isRegistration,
      password,
      deviceId,
    });
    res.json(result);
  } catch (err) {
    const status = err.status || 400;
    res.status(status).json({
      success: false,
      error: err.message,
      code: err.code || 'AUTH_ERROR',
      alreadyRegistered: !!err.alreadyRegistered,
      notRegistered: !!err.notRegistered,
      deviceBlocked: err.code === 'DEVICE_BLOCKED',
    });
  }
});

/**
 * POST /api/auth/login-password
 * Authenticates a student using email + password (no OTP required)
 */
router.post('/auth/login-password', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'Email and password are required.' });
    }

    const result = await authService.loginWithPassword(email, password);
    res.json(result);
  } catch (err) {
    const status = err.status || 400;
    res.status(status).json({
      success: false,
      error: err.message,
      code: err.code || 'AUTH_ERROR',
      notRegistered: !!err.notRegistered,
      noPassword: !!err.noPassword,
    });
  }
});

/**
 * POST /api/auth/verify-otp
 * Verifies submitted 6-digit code, deletes OTP, and issues session JWT
 */
router.post('/auth/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({ success: false, error: 'Both email and 6-digit OTP are required.' });
    }

    const result = await authService.verifyOtp(email, otp);
    res.json(result);
  } catch (err) {
    const status = err.status || 400;
    res.status(status).json({
      success: false,
      error: err.message,
      code: err.code || 'AUTH_ERROR',
      alreadyRegistered: !!err.alreadyRegistered,
    });
  }
});

/**
 * POST /api/auth/set-password
 * Sets or updates password for a user account identified by auth token or email
 */
router.post('/auth/set-password', optionalAuth, async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!password) {
      return res.status(400).json({ success: false, error: 'Password is required.' });
    }

    const targetEmail = req.student?.email || (email ? email.trim().toLowerCase() : null);
    if (!targetEmail) {
      return res.status(400).json({ success: false, error: 'Email is required.' });
    }

    const result = await authService.setPassword(targetEmail, password);
    res.json(result);
  } catch (err) {
    const status = err.status || 400;
    res.status(status).json({
      success: false,
      error: err.message,
      code: err.code || 'AUTH_ERROR',
    });
  }
});

/**
 * GET /api/auth/has-password?email=...
 * Checks whether the student account has a password set
 */
router.get('/auth/has-password', (req, res) => {
  const email = req.query.email?.trim().toLowerCase();
  if (!email) {
    return res.status(400).json({ success: false, error: 'Email parameter is required.' });
  }
  const hasPassword = authService.checkHasPassword(email);
  res.json({ success: true, email, hasPassword });
});

/**
 * POST /api/auth/send-verification-link
 * Sends an email verification link.
 * Supports Google Sign-In, email sign-in, and registration flows.
 */
router.post('/auth/send-verification-link', async (req, res) => {
  try {
    const { email, displayName, isRegistration, isSignIn, fullName, studentId, department, semester, password } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, error: 'Email address is required.' });
    }
    const result = await authService.requestEmailVerification(email, displayName, {
      isRegistration,
      isSignIn,
      fullName,
      studentId,
      department,
      semester,
      password,
    });
    res.json(result);
  } catch (err) {
    const status = err.status || 400;
    res.status(status).json({
      success: false,
      error: err.message,
      code: err.code || 'AUTH_ERROR',
      alreadyRegistered: !!err.alreadyRegistered,
      notRegistered: !!err.notRegistered,
    });
  }
});

/**
 * GET /api/auth/verify-email?token=...
 * Called when the user clicks the verification link in their email.
 * Returns an HTML page confirming verification.
 */
router.get('/auth/verify-email', (req, res) => {
  const { token } = req.query;
  if (!token) {
    return res.status(400).send(renderVerificationPage(false, 'Missing verification token.'));
  }

  const result = authService.verifyEmailToken(token);
  if (result.success) {
    return res.send(renderVerificationPage(true, `Email ${result.email} verified successfully! You can close this tab and return to the app.`));
  } else {
    return res.send(renderVerificationPage(false, result.error));
  }
});

/**
 * GET /api/auth/check-verification?email=...
 * Polled by the frontend to check if the email has been verified via the link.
 */
router.get('/auth/check-verification', (req, res) => {
  const email = req.query.email?.trim().toLowerCase();
  if (!email) {
    return res.status(400).json({ success: false, error: 'Email parameter is required.' });
  }
  const result = authService.checkEmailVerification(email);
  res.json({ success: true, ...result });
});

/**
 * POST /api/auth/forgot-password
 * Sends a password reset link to the user's email.
 */
router.post('/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, error: 'Email address is required.' });
    }
    const result = await authService.requestPasswordReset(email);
    res.json(result);
  } catch (err) {
    const status = err.status || 400;
    res.status(status).json({
      success: false,
      error: err.message,
      code: err.code || 'AUTH_ERROR',
    });
  }
});

/**
 * GET /api/auth/reset-password?token=...
 * Renders the password reset form (HTML page).
 */
router.get('/auth/reset-password', (req, res) => {
  const { token } = req.query;
  if (!token) {
    return res.send(renderResetPasswordPage(null, 'Missing reset token.'));
  }

  const result = authService.validateResetToken(token);
  if (!result.valid) {
    return res.send(renderResetPasswordPage(null, result.error));
  }
  return res.send(renderResetPasswordPage(token, null, result.email));
});

/**
 * POST /api/auth/reset-password
 * Processes the password reset form submission.
 */
router.post('/auth/reset-password', (req, res) => {
  try {
    const { token, password } = req.body;
    if (!token || !password) {
      // If browser form submit (not JSON)
      if (req.is('application/x-www-form-urlencoded')) {
        return res.send(renderResetPasswordPage(token, 'Token and password are required.'));
      }
      return res.status(400).json({ success: false, error: 'Token and password are required.' });
    }

    const result = authService.resetPasswordWithToken(token, password);

    if (req.is('application/x-www-form-urlencoded')) {
      return res.send(renderResetSuccessPage());
    }
    res.json(result);
  } catch (err) {
    if (req.is('application/x-www-form-urlencoded')) {
      return res.send(renderResetPasswordPage(req.body?.token, err.message));
    }
    const status = err.status || 400;
    res.status(status).json({
      success: false,
      error: err.message,
      code: err.code || 'AUTH_ERROR',
    });
  }
});

/**
 * GET /api/auth/me
 * Retrieves student profile for active session token
 */
router.get('/auth/me', requireAuth, (req, res) => {
  res.json({ success: true, student: req.student });
});

// ===================== HTML PAGE RENDERERS =====================

function renderVerificationPage(success, message) {
  const color = success ? '#10B981' : '#EF4444';
  const icon = success ? '✅' : '❌';
  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edutools — Email Verification</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:'Segoe UI',system-ui,sans-serif;background:#0a0a0a;color:#fafafa;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
  .card{max-width:440px;width:100%;background:#141414;border:1px solid #262626;border-radius:20px;padding:40px;text-align:center}
  .icon{font-size:56px;margin-bottom:16px}
  h1{font-size:22px;font-weight:700;margin-bottom:8px;color:${color}}
  p{font-size:14px;color:#a3a3a3;line-height:1.6;margin-bottom:24px}
  .brand{font-size:12px;color:#525252;margin-top:16px}
</style></head>
<body>
<div class="card">
  <div class="icon">${icon}</div>
  <h1>${success ? 'Email Verified!' : 'Verification Failed'}</h1>
  <p>${message}</p>
  <p class="brand">Edutools &bull; United International University</p>
</div>
</body></html>`;
}

function renderResetPasswordPage(token, error, email) {
  const errorHtml = error
    ? `<div style="background:#7f1d1d;border:1px solid #ef4444;border-radius:10px;padding:12px;margin-bottom:16px;color:#fca5a5;font-size:13px">${error}</div>`
    : '';

  if (!token) {
    return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edutools — Reset Password</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:'Segoe UI',system-ui,sans-serif;background:#0a0a0a;color:#fafafa;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
  .card{max-width:440px;width:100%;background:#141414;border:1px solid #262626;border-radius:20px;padding:40px;text-align:center}
  h1{font-size:22px;font-weight:700;margin-bottom:8px;color:#EF4444}
  p{font-size:14px;color:#a3a3a3;line-height:1.6}
</style></head>
<body><div class="card"><h1>Invalid Reset Link</h1>${errorHtml}<p>${error || 'This password reset link is invalid or has expired.'}</p></div></body></html>`;
  }

  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edutools — Reset Password</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:'Segoe UI',system-ui,sans-serif;background:#0a0a0a;color:#fafafa;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
  .card{max-width:440px;width:100%;background:#141414;border:1px solid #262626;border-radius:20px;padding:40px}
  .logo{text-align:center;margin-bottom:24px}
  .logo h1{color:#f97316;font-size:24px;font-weight:800}
  .logo p{color:#737373;font-size:12px}
  label{display:block;font-size:13px;font-weight:600;color:#d4d4d4;margin-bottom:6px}
  input{width:100%;padding:12px 14px;background:#1e1e1e;border:1px solid #333;border-radius:10px;color:#fafafa;font-size:14px;margin-bottom:14px;font-family:inherit}
  input:focus{outline:none;border-color:#f97316}
  button{width:100%;padding:14px;background:linear-gradient(135deg,#f97316,#ea580c);color:#fff;border:none;border-radius:12px;font-size:15px;font-weight:700;cursor:pointer;font-family:inherit}
  button:hover{opacity:0.9}
  .email{text-align:center;color:#f97316;font-weight:700;font-size:14px;margin-bottom:16px}
</style></head>
<body>
<div class="card">
  <div class="logo"><h1>Edutools &bull; UIU</h1><p>Reset Your Password</p></div>
  ${email ? `<p class="email">${email}</p>` : ''}
  ${errorHtml}
  <form method="POST" action="/api/auth/reset-password">
    <input type="hidden" name="token" value="${token}">
    <label>New Password</label>
    <input type="password" name="password" placeholder="Min 6 characters" minlength="6" required>
    <label>Confirm Password</label>
    <input type="password" id="confirmPw" placeholder="Confirm new password" minlength="6" required>
    <button type="submit">Reset Password</button>
  </form>
  <script>
    document.querySelector('form').addEventListener('submit', function(e) {
      const pw = document.querySelector('input[name="password"]').value;
      const cpw = document.getElementById('confirmPw').value;
      if (pw !== cpw) { e.preventDefault(); alert('Passwords do not match.'); }
    });
  </script>
</div>
</body></html>`;
}

function renderResetSuccessPage() {
  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Edutools — Password Reset</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{font-family:'Segoe UI',system-ui,sans-serif;background:#0a0a0a;color:#fafafa;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
  .card{max-width:440px;width:100%;background:#141414;border:1px solid #262626;border-radius:20px;padding:40px;text-align:center}
  h1{font-size:22px;font-weight:700;margin-bottom:8px;color:#10B981}
  p{font-size:14px;color:#a3a3a3;line-height:1.6}
</style></head>
<body>
<div class="card">
  <div style="font-size:56px;margin-bottom:16px">✅</div>
  <h1>Password Reset Successfully!</h1>
  <p>You can now sign in with your new password. You may close this tab.</p>
  <p style="color:#525252;font-size:12px;margin-top:16px">Edutools &bull; United International University</p>
</div>
</body></html>`;
}

// ===================== 2. FILE UPLOAD ENDPOINT =====================

/**
 * POST /api/upload
 * Validates student file type, enforces 10MB limit, extracts events, and synchronizes to calendar
 */
router.post('/upload', optionalAuth, (req, res) => {
  upload.single('file')(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ success: false, error: 'File exceeds maximum 10 MB size limit.' });
      }
      return res.status(400).json({ success: false, error: err.message });
    } else if (err) {
      return res.status(400).json({ success: false, error: err.message });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, error: 'No file was uploaded.' });
    }

    try {
      const email = req.student ? req.student.email : (req.body.email || 'student@university.edu');
      const fileId = `FILE-${Date.now()}`;

      // Extract events from uploaded document
      const parseResult = calendarSyncService.parseScheduleFile(
        req.file.path,
        req.file.originalname,
        null
      );

      // Auto-synchronize to connected calendar
      const syncResult = calendarSyncService.synchronizeCalendar(email, parseResult.events, {
        fileId,
        filename: req.file.originalname,
        size: req.file.size,
        path: req.file.path,
      });

      // Get updated sync verification report
      const syncStatus = calendarSyncService.verifySyncStatus(email);

      res.json({
        success: true,
        message: `File "${req.file.originalname}" uploaded and synced successfully.`,
        file: {
          fileId,
          originalName: req.file.originalname,
          sizeBytes: req.file.size,
          sizeKb: (req.file.size / 1024).toFixed(1),
          mimetype: req.file.mimetype,
        },
        parseResult,
        syncResult,
        syncStatus,
      });
    } catch (parseErr) {
      res.status(400).json({ success: false, error: parseErr.message });
    }
  });
});

// ===================== 3. CALENDAR SYNCHRONIZATION & STATUS VERIFICATION =====================

/**
 * POST /api/calendar/sync
 * Manually pushes raw schedule payload (JSON/CSV/ICS text) into calendar database
 */
router.post('/calendar/sync', optionalAuth, (req, res) => {
  try {
    const { rawSchedule, events, email } = req.body;
    const targetEmail = req.student ? req.student.email : (email || 'student@university.edu');

    let eventsToSync = [];
    if (events && Array.isArray(events)) {
      eventsToSync = events;
    } else if (rawSchedule) {
      const parsed = calendarSyncService.parseScheduleFile(null, 'manual_sync.txt', Buffer.from(rawSchedule, 'utf-8'));
      eventsToSync = parsed.events;
    } else {
      return res.status(400).json({ success: false, error: 'Provide either events array or rawSchedule text.' });
    }

    const syncResult = calendarSyncService.synchronizeCalendar(targetEmail, eventsToSync, {
      fileId: `MANUAL-${Date.now()}`,
      filename: 'direct_sync',
      size: Buffer.byteLength(JSON.stringify(eventsToSync)),
    });

    const syncStatus = calendarSyncService.verifySyncStatus(targetEmail);

    res.json({
      success: true,
      syncResult,
      syncStatus,
    });
  } catch (err) {
    const status = err.status || 400;
    res.status(status).json({
      success: false,
      error: err.message,
      code: err.code || 'AUTH_ERROR',
      alreadyRegistered: !!err.alreadyRegistered,
    });
  }
});

/**
 * GET /api/calendar/sync-status
 * Compares entries found in uploaded schedule against actual calendar DB entries
 * Flags missing, duplicate, and misaligned events with full audit report
 */
router.get('/calendar/sync-status', optionalAuth, (req, res) => {
  try {
    const email = req.student ? req.student.email : (req.query.email || 'student@university.edu');
    const statusReport = calendarSyncService.verifySyncStatus(email);
    res.json(statusReport);
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ===================== 4. HEALTH CHECK & SYSTEM DIAGNOSTICS =====================

/**
 * GET /api/health
 * System health and diagnostic status
 */
router.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'Edutools Core Full-Stack API',
    features: {
      universityEmailOtp: 'active',
      fileUploadLimits: '10MB enforced',
      calendarSyncVerification: 'active',
    },
    version: '1.0.0',
  });
});


// ===================== 5. GLOBAL & STUDENT CLOUD SYNC ENDPOINTS =====================
// Uses MongoDB for persistence with in-memory fallback if DB is unavailable

const { isConnected } = require('../db');
const StudentSchedule = require('../models/StudentSchedule');
const GlobalBroadcast = require('../models/GlobalBroadcast');

// In-memory fallback stores (used only when MongoDB is unavailable)
let memGlobalBroadcast = {
  version: Date.now(),
  source: 'Official Academic Server',
  notices: [],
  classes: [],
  updatedAt: new Date().toISOString(),
};
const memStudentStore = new Map();

/**
 * GET /api/calendar/global-sync
 * Retrieves latest synchronized global calendar state
 */
router.get('/calendar/global-sync', async (req, res) => {
  try {
    if (isConnected()) {
      const doc = await GlobalBroadcast.findOne({ key: 'global' }).lean();
      if (doc) {
        return res.json({
          version: doc.version,
          source: doc.source,
          notices: doc.notices,
          classes: doc.classes,
          updatedAt: doc.updatedAt,
        });
      }
    }
    res.json(memGlobalBroadcast);
  } catch (err) {
    res.json(memGlobalBroadcast);
  }
});

/**
 * POST /api/calendar/global-update
 * Updates global broadcast schedule (persisted to MongoDB)
 */
router.post('/calendar/global-update', async (req, res) => {
  const { source, notices, classes } = req.body;
  const version = Date.now();
  const now = new Date().toISOString();

  const update = {};
  if (Array.isArray(notices) && notices.length > 0) update.notices = notices;
  if (Array.isArray(classes)) update.classes = classes;
  update.version = version;
  update.source = source || 'PC Web Client';
  update.updatedAt = now;

  // Always update in-memory for fast reads
  Object.assign(memGlobalBroadcast, update);

  try {
    if (isConnected()) {
      await GlobalBroadcast.findOneAndUpdate(
        { key: 'global' },
        { $set: update },
        { upsert: true, new: true }
      );
    }
  } catch (err) {
    console.warn('[SYNC] MongoDB global-update write failed, in-memory only:', err.message);
  }

  res.json({ success: true, version });
});

/**
 * GET /api/student/sync
 * Retrieves student profile & schedule from MongoDB (or in-memory fallback)
 * Enriches profile with authoritative data from auth registration if available
 */
router.get('/student/sync', async (req, res) => {
  const email = (req.query.email || '').trim().toLowerCase();
  if (!email) {
    return res.json({ success: true, classes: [], student: null });
  }

  let syncedStudent = null;
  let syncedClasses = [];

  try {
    if (isConnected()) {
      const doc = await StudentSchedule.findOne({ email }).lean();
      if (doc) {
        syncedStudent = doc.student || null;
        syncedClasses = doc.classes || [];
      }
    }
  } catch (err) {
    console.warn('[SYNC] MongoDB student read failed:', err.message);
  }

  if (!syncedStudent) {
    const record = memStudentStore.get(email) || { classes: [], student: null };
    syncedStudent = record.student || null;
    if (record.classes && record.classes.length > 0) syncedClasses = record.classes;
  }

  // Enrich with authoritative profile from auth registration
  const authProfile = authService.studentStore.get(email);
  if (authProfile && syncedStudent) {
    syncedStudent = {
      ...syncedStudent,
      fullName: authProfile.fullName || syncedStudent.fullName,
      studentId: authProfile.studentId || syncedStudent.studentId,
      department: authProfile.department || syncedStudent.department,
    };
  } else if (authProfile && !syncedStudent) {
    syncedStudent = authProfile;
  }

  res.json({ success: true, classes: syncedClasses, student: syncedStudent });
});

/**
 * POST /api/student/sync
 * Persists student profile & schedule to MongoDB (with in-memory fallback)
 */
router.post('/student/sync', async (req, res) => {
  const { email, student, classes } = req.body;
  const targetEmail = (email || student?.email || '').trim().toLowerCase();
  if (!targetEmail) {
    return res.json({ success: true, classes: classes || [] });
  }

  const classArray = Array.isArray(classes) ? classes : [];
  const now = new Date();

  // Always update in-memory
  memStudentStore.set(targetEmail, { student, classes: classArray, updatedAt: now.toISOString() });

  try {
    if (isConnected()) {
      await StudentSchedule.findOneAndUpdate(
        { email: targetEmail },
        { $set: { student, classes: classArray, updatedAt: now } },
        { upsert: true, new: true }
      );
    }
  } catch (err) {
    console.warn('[SYNC] MongoDB student write failed, in-memory only:', err.message);
  }

  res.json({ success: true, classes: classArray });
});

module.exports = router;
