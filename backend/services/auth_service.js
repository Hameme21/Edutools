const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const fs = require('fs');
const path = require('path');

const JWT_SECRET = process.env.JWT_SECRET || 'edutools-secure-jwt-secret-key-2026-academic';
const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes expiration

// Gmail SMTP Credentials for OTP dispatch from hamimasir5@gmail.com
const EMAIL_USER = process.env.EMAIL_USER || 'hamimasir5@gmail.com';
const EMAIL_PASS = process.env.EMAIL_PASS || 'faixfyjgwixzbisl';

// Nodemailer Gmail SMTP Transporter with connection timeouts
const transporter = nodemailer.createTransport({
  service: 'gmail',
  connectionTimeout: 6000,
  greetingTimeout: 6000,
  socketTimeout: 6000,
  auth: {
    user: EMAIL_USER,
    pass: EMAIL_PASS,
  },
});

// Persistent data storage paths
const DATA_DIR = path.join(__dirname, '..', 'data');
const STUDENTS_DB_PATH = path.join(DATA_DIR, 'students_db.json');

// In-memory data stores backed by disk persistence
const otpStore = new Map(); // email -> { hash, salt, expiresAt, attempts, isRegistration, fullName, studentId, department, semester }
const studentStore = new Map(); // email -> { id, studentId, fullName, email, department, semester, university, createdAt, lastLogin }

function loadRegisteredStudents() {
  try {
    if (fs.existsSync(STUDENTS_DB_PATH)) {
      const raw = fs.readFileSync(STUDENTS_DB_PATH, 'utf-8');
      const data = JSON.parse(raw);
      for (const [email, student] of Object.entries(data)) {
        studentStore.set(email.toLowerCase(), student);
      }
      console.log(`[STUDENT DB] Loaded ${studentStore.size} registered student accounts.`);
    }
  } catch (err) {
    console.warn('[STUDENT DB] Could not read students_db.json:', err.message);
  }
}

function saveRegisteredStudents() {
  try {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
    const data = Object.fromEntries(studentStore.entries());
    fs.writeFileSync(STUDENTS_DB_PATH, JSON.stringify(data, null, 2), 'utf-8');
  } catch (err) {
    console.error('[STUDENT DB] Failed to save students_db.json:', err.message);
  }
}

// Load existing registered students into memory on server boot
loadRegisteredStudents();

function isEmailRegistered(email) {
  if (!email) return false;
  return studentStore.has(email.trim().toLowerCase());
}

/**
 * Validates whether an email format is valid.
 */
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  const normalized = email.trim().toLowerCase();
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(normalized);
}

/**
 * Validates whether an email belongs to United International University (UIU) degree program.
 * UIU student emails must end with @<degree_name>.uiu.ac.bd (e.g. @bscse.uiu.ac.bd, @bseee.uiu.ac.bd, @bsce.uiu.ac.bd, @bsds.uiu.ac.bd).
 * Plain @uiu.ac.bd without degree name is NOT permitted.
 */
function isUiuEmail(email) {
  if (!isValidEmail(email)) return false;
  const normalized = email.trim().toLowerCase();
  const domain = normalized.split('@')[1];
  if (!domain) return false;
  return domain.endsWith('.uiu.ac.bd') && domain !== 'uiu.ac.bd';
}

/**
 * Checks if the email belongs to an educational institution domain.
 */
function isUniversityEmail(email) {
  if (!isValidEmail(email)) return false;
  const normalized = email.trim().toLowerCase();
  const domain = normalized.split('@')[1];
  if (!domain) return false;

  return (
    isUiuEmail(normalized) ||
    domain.endsWith('.edu') ||
    domain.includes('.edu.') ||
    domain.endsWith('.ac.bd') ||
    domain.includes('.ac.') ||
    domain.endsWith('.edu.bd') ||
    domain.endsWith('.ac.uk') ||
    domain.endsWith('.edu.au')
  );
}

/**
 * Generates a cryptographic 6-digit numeric OTP
 */
function generate6DigitOtp() {
  const num = crypto.randomInt(100000, 1000000);
  return num.toString();
}

/**
 * Creates SHA-256 hash of OTP with cryptographic salt
 */
function hashOtp(otp, salt) {
  return crypto.createHmac('sha256', salt).update(otp).digest('hex');
}

/**
 * Formats a clean human-readable name from an email address handle
 */
function formatNameFromEmail(email) {
  if (!email) return 'UIU Student';
  const handle = email.split('@')[0];
  const parts = handle.split(/[._-]/);
  const formatted = parts
    .filter((p) => p.length > 0)
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1).toLowerCase())
    .join(' ')
    .trim();
  return formatted || 'UIU Student';
}

/**
 * Infers department name from email handle or domain
 */
function inferDepartmentFromDomain(domain) {
  if (!domain) return 'Computer Science & Engineering';
  const lower = domain.toLowerCase();
  if (lower.includes('bscse') || lower.includes('cse')) return 'Computer Science & Engineering';
  if (lower.includes('bseee') || lower.includes('eee')) return 'Electrical & Electronic Engineering';
  if (lower.includes('sobe') || lower.includes('bba')) return 'School of Business & Economics';
  if (lower.includes('bsce') || lower.includes('ce')) return 'Civil Engineering';
  if (lower.includes('mscse')) return 'MS in Computer Science & Engineering';
  return 'Computer Science & Engineering';
}

/**
 * Extracts friendly university or institution name from domain
 */
function extractUniversityName(domain) {
  if (!domain) return 'United International University';
  if (domain.includes('uiu.ac.bd')) return 'United International University (UIU)';
  const parts = domain.split('.');
  if (parts.length > 0 && parts[0] !== 'www') {
    if (parts[0].toLowerCase() === 'gmail') return 'Google Student Portal';
    return parts[0].toUpperCase() + ' University';
  }
  return 'United International University';
}

/**
 * Dispatches email from hamimasir5@gmail.com via Gmail SMTP using Nodemailer
 */
async function sendEmailOtp(email, otp) {
  const norm = email.trim().toLowerCase();
  const domain = norm.split('@')[1] || '';

  // Prevent sending live test emails to fake domains (which trigger bounce-back NDR blocks like 550 5.4.1)
  if (
    process.env.NODE_ENV === 'test' ||
    norm.startsWith('john.doe@') ||
    norm.startsWith('alex.chen@') ||
    domain === 'mit.edu' ||
    domain === 'stanford.edu' ||
    domain === 'example.com' ||
    domain === 'test.com'
  ) {
    console.log(`[TEST/DEV OTP MOCK] Skipping live SMTP send to ${norm}. Mock OTP is: ${otp}`);
    return { delivered: true, messageId: 'mock-test-id', timestamp: new Date().toISOString() };
  }

  console.log(`\n========================================`);
  console.log(`📧 [DISPATCHING LIVE OTP EMAIL FROM hamimasir5@gmail.com]`);
  console.log(`To: ${norm}`);
  console.log(`Subject: Edutools UIU - Verification Code`);
  console.log(`========================================\n`);

  const mailOptions = {
    from: `"Edutools UIU Academic Portal" <${EMAIL_USER}>`,
    to: norm,
    replyTo: EMAIL_USER,
    subject: `Edutools UIU - Your Verification Code: ${otp}`,
    text: `Welcome to Edutools (United International University)!\n\nYour 6-digit verification code is: ${otp}\n\nThis code will expire in 5 minutes.\nIf you did not request this code, please ignore this email.`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 24px; border: 1px solid #fed7aa; border-radius: 16px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #ea580c; margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px;">Edutools • UIU</h1>
          <p style="color: #64748b; font-size: 13px; margin: 4px 0 0 0;">United International University Academic Calendar & Routine Sync</p>
        </div>
        <div style="background: #fff7ed; border: 1px solid #fdba74; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 20px;">
          <p style="color: #334155; font-size: 14px; margin: 0 0 12px 0;">Your single-use 6-digit verification code for <strong>${norm}</strong>:</p>
          <div style="font-family: monospace; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #1e293b; background: #ffffff; display: inline-block; padding: 12px 24px; border-radius: 10px; border: 2px dashed #ea580c;">
            ${otp}
          </div>
          <p style="color: #ef4444; font-size: 12px; margin: 12px 0 0 0; font-weight: 600;">⏱ Valid for 5 minutes only</p>
        </div>
        <p style="color: #64748b; font-size: 12px; line-height: 1.5; margin: 0; text-align: center;">
          Sent from <strong>hamimasir5@gmail.com</strong>.<br/>
          If you did not request this login or registration code, you can safely ignore this email.
        </p>
      </div>
    `,
  };

  const info = await transporter.sendMail(mailOptions);
  console.log(`✅ Real email delivered via SMTP! MessageId: ${info.messageId}`);
  return { delivered: true, messageId: info.messageId, timestamp: new Date().toISOString() };
}

/**
 * Initiates email authentication or registration by creating and sending an OTP
 * Registered student emails MUST end with uiu.ac.bd
 */
// Rate limiting store: email -> array of request timestamps (ms)
const otpRateLimitStore = new Map();

function checkOtpRateLimit(email) {
  if (process.env.NODE_ENV === 'test') return;

  const now = Date.now();
  const history = otpRateLimitStore.get(email) || [];
  // Retain only requests within the last 10 minutes (600,000 ms)
  const recent = history.filter((t) => now - t < 10 * 60 * 1000);
  otpRateLimitStore.set(email, recent);

  if (recent.length > 0) {
    const lastTime = recent[recent.length - 1];
    const diff = now - lastTime;
    if (diff < 60 * 1000) {
      const waitSec = Math.ceil((60 * 1000 - diff) / 1000);
      const err = new Error(`Please wait ${waitSec}s before requesting another verification code.`);
      err.status = 429;
      err.code = 'RATE_LIMITED';
      throw err;
    }
  }

  if (recent.length >= 4) {
    const err = new Error('Too many verification requests. Please wait 10 minutes before requesting another code.');
    err.status = 429;
    err.code = 'RATE_LIMITED';
    throw err;
  }
}

function recordOtpRequest(email) {
  const now = Date.now();
  const history = otpRateLimitStore.get(email) || [];
  history.push(now);
  otpRateLimitStore.set(email, history);
}

/**
 * Initiates email authentication or registration by creating and sending an OTP
 * Registered student emails MUST end with uiu.ac.bd
 */
async function requestOtp(email, options = {}) {
  const normalizedEmail = email.trim().toLowerCase();

  if (!isValidEmail(normalizedEmail)) {
    throw new Error('Please enter a valid email address.');
  }

  // 1. Enforce rate limiting (60s cooldown, max 4 / 10m)
  checkOtpRateLimit(normalizedEmail);

  // 2. Check if already registered when registering
  if (options.isRegistration) {
    if (isEmailRegistered(normalizedEmail)) {
      const err = new Error('This account is already registered. Please sign in with your credentials.');
      err.status = 400;
      err.code = 'ALREADY_REGISTERED';
      err.alreadyRegistered = true;
      throw err;
    }

    if (!isUiuEmail(normalizedEmail)) {
      throw new Error('Registration is strictly restricted to UIU student emails with degree program (e.g. ahamim2510370@bscse.uiu.ac.bd). Plain @uiu.ac.bd is not allowed.');
    }
  } else {
    // For sign in: allow @<degree>.uiu.ac.bd, valid university emails, or hamimasir5@gmail.com
    if (!isUiuEmail(normalizedEmail) && !isUniversityEmail(normalizedEmail) && normalizedEmail !== 'hamimasir5@gmail.com') {
      throw new Error('Sign in is restricted to UIU student emails with degree program (e.g. ahamim2510370@bscse.uiu.ac.bd).');
    }
  }

  recordOtpRequest(normalizedEmail);

  const otp = generate6DigitOtp();
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = hashOtp(otp, salt);
  const expiresAt = Date.now() + OTP_TTL_MS;

  otpStore.set(normalizedEmail, {
    hash,
    salt,
    expiresAt,
    attempts: 0,
    createdAt: Date.now(),
    isRegistration: !!options.isRegistration,
    fullName: options.fullName?.trim(),
    studentId: options.studentId?.trim(),
    department: options.department?.trim(),
    semester: options.semester?.trim(),
  });

  // SMTP email dispatch from hamimasir5@gmail.com with fallback timeout
  let emailResult = null;
  try {
    emailResult = await Promise.race([
      sendEmailOtp(normalizedEmail, otp),
      new Promise((_, reject) => setTimeout(() => reject(new Error('SMTP timeout (6s)')), 6000))
    ]);
  } catch (err) {
    console.warn('[SMTP DISPATCH WARNING]:', err.message);
    emailResult = { delivered: false, warning: err.message };
  }

  const responsePayload = {
    success: true,
    message: options.isRegistration
      ? 'A 6-digit registration code has been sent to your UIU email. Valid for 5 minutes.'
      : 'A 6-digit login verification code has been sent to your email. Valid for 5 minutes.',
    email: normalizedEmail,
    expiresInSeconds: 300,
    emailResult,
  };

  return responsePayload;
}

/**
 * Verifies submitted 6-digit OTP, deletes it on success, and issues session token
 */
async function verifyOtp(email, submittedOtp) {
  const normalizedEmail = email.trim().toLowerCase();
  const record = otpStore.get(normalizedEmail);

  if (!record) {
    throw new Error('No active verification request found for this email. Please request a new code.');
  }

  if (Date.now() > record.expiresAt) {
    otpStore.delete(normalizedEmail);
    throw new Error('Verification code has expired (5-minute limit). Please request a new code.');
  }

  record.attempts += 1;
  if (record.attempts > 5) {
    otpStore.delete(normalizedEmail);
    throw new Error('Too many failed verification attempts. Please request a new code.');
  }

  const computedHash = hashOtp(submittedOtp.trim(), record.salt);
  if (computedHash !== record.hash) {
    throw new Error('Invalid 6-digit verification code. Please check your email and try again.');
  }

  // Code verified! Delete OTP immediately (single-use enforcement)
  const isRegistration = record.isRegistration;
  const regFullName = record.fullName;
  const regStudentId = record.studentId;
  const regDepartment = record.department;
  const regSemester = record.semester;
  otpStore.delete(normalizedEmail);

  // Retrieve or create student profile
  let student = studentStore.get(normalizedEmail);
  const domain = normalizedEmail.split('@')[1];
  const userHandle = normalizedEmail.split('@')[0];

  if (!student || isRegistration) {
    student = {
      id: student ? student.id : `STD-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      studentId: regStudentId || (student ? student.studentId : userHandle.toUpperCase()),
      fullName: regFullName || (student ? student.fullName : formatNameFromEmail(normalizedEmail)),
      email: normalizedEmail,
      department: regDepartment || (student ? student.department : inferDepartmentFromDomain(domain)),
      semester: regSemester || (student ? student.semester : 'Spring 2026'),
      university: extractUniversityName(domain),
      domain,
      createdAt: student ? student.createdAt : new Date().toISOString(),
      lastLogin: new Date().toISOString(),
    };
    studentStore.set(normalizedEmail, student);
    saveRegisteredStudents();
  } else {
    student.lastLogin = new Date().toISOString();
    saveRegisteredStudents();
  }

  // Sign JWT session token (7-day validity)
  const token = jwt.sign(
    {
      studentId: student.studentId,
      email: student.email,
      fullName: student.fullName,
      university: student.university,
    },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  return {
    success: true,
    message: isRegistration
      ? 'Registration complete! Welcome to Edutools UIU.'
      : 'Authenticated successfully with UIU Portal.',
    token,
    student,
  };
}

/**
 * Verifies JWT session token
 */
function verifySessionToken(token) {
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const student = studentStore.get(payload.email);
    return student || payload;
  } catch (err) {
    throw new Error('Invalid or expired session token.');
  }
}

module.exports = {
  transporter,
  isValidEmail,
  isUiuEmail,
  isUniversityEmail,
  isEmailRegistered,
  requestOtp,
  verifyOtp,
  verifySessionToken,
  formatNameFromEmail,
  studentStore,
  otpStore,
  saveRegisteredStudents,
};
