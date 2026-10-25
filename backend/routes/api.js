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
    const { email, fullName, studentId, department, semester, isRegistration } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, error: 'Email address is required.' });
    }

    const result = await authService.requestOtp(email, {
      fullName,
      studentId,
      department,
      semester,
      isRegistration,
    });
    res.json(result);
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
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
    res.status(400).json({ success: false, error: err.message });
  }
});

/**
 * GET /api/auth/me
 * Retrieves student profile for active session token
 */
router.get('/auth/me', requireAuth, (req, res) => {
  res.json({ success: true, student: req.student });
});

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
    res.status(400).json({ success: false, error: err.message });
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

module.exports = router;
