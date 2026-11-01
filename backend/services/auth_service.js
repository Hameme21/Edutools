require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const emailService = require('./email_service');
const fs = require('fs');
const path = require('path');

const JWT_SECRET = process.env.JWT_SECRET || 'edutools-secure-jwt-secret-key-2026-academic';
const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes expiration
const VERIFICATION_TTL_MS = 15 * 60 * 1000; // 15 minutes for email verification links
const RESET_TTL_MS = 15 * 60 * 1000; // 15 minutes for password reset links

const BACKEND_URL = process.env.RENDER_EXTERNAL_URL || process.env.BACKEND_URL || 'http://localhost:3000';

// Email delivery uses Brevo over HTTPS; credentials stay on the backend.
const EMAIL_FROM = process.env.EMAIL_FROM?.trim();

// Persistent data storage paths
const DATA_DIR = path.join(__dirname, '..', 'data');
const STUDENTS_DB_PATH = path.join(DATA_DIR, 'students_db.json');

// In-memory data stores backed by disk persistence
const otpStore = new Map(); // email -> { hash, salt, expiresAt, attempts, isRegistration, fullName, studentId, department, semester }
const studentStore = new Map(); // email -> { id, studentId, fullName, email, department, semester, university, createdAt, lastLogin }
const emailVerificationStore = new Map(); // token -> { email, expiresAt, verified, displayName }
const emailVerifiedSet = new Map(); // email -> { verified: true, displayName, verifiedAt }
const passwordResetStore = new Map(); // token -> { email, expiresAt, used }

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
 * Hashes a password using PBKDF2 with a random salt
 */
function hashPassword(password) {
  const salt = crypto.randomBytes(32).toString('hex');
  const hash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha512').toString('hex');
  return { hash, salt };
}

/**
 * Verifies a password against stored hash and salt
 */
function verifyPassword(password, storedHash, storedSalt) {
  const hash = crypto.pbkdf2Sync(password, storedSalt, 100000, 64, 'sha512').toString('hex');
  return hash === storedHash;
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
 * Dispatches OTP email via the Brevo HTTPS API
 */
async function sendEmailOtp(email, otp) {
  const norm = email.trim().toLowerCase();
  if (process.env.NODE_ENV === 'test') {
    console.log(`[TEST/DEV OTP MOCK] Skipping live EMAIL_API send to ${norm}. Mock OTP is: ${otp}`);
    return { delivered: true, messageId: 'mock-test-id', timestamp: new Date().toISOString() };
  }

  console.log(`\n========================================`);
  console.log(`📧 [DISPATCHING LIVE OTP EMAIL]`);
  console.log(`From: ${EMAIL_FROM}`);
  console.log(`To: ${norm}`);
  console.log(`Subject: Edutools UIU - Verification Code`);
  console.log(`========================================\n`);

  const mailOptions = {
    from: { name: 'Edutools UIU Academic Portal', email: EMAIL_FROM },
    to: norm,
    replyTo: EMAIL_FROM,
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
          Sent from <strong>${EMAIL_FROM}</strong>.<br/>
          If you did not request this login or registration code, you can safely ignore this email.
        </p>
      </div>
    `,
  };

  const info = await emailService.sendEmail(mailOptions);

  console.log(`✅ [EMAIL API ACCEPTED] MessageId: ${info.messageId} | accepted: ${JSON.stringify(info.accepted)} | rejected: ${JSON.stringify(info.rejected)}`);
  return { delivered: true, messageId: info.messageId, timestamp: new Date().toISOString() };
}

/**
 * Initiates email authentication or registration by creating and sending an OTP
 * Registered student emails MUST end with uiu.ac.bd
 */
// Rate limiting store: email -> array of request timestamps (ms)
const otpRateLimitStore = new Map();

// Device-level rate limiting: deviceId -> { count, blocked }
// After 6 OTP requests from a single device, block it permanently
const deviceRateLimitStore = new Map();

function checkDeviceRateLimit(deviceId) {
  if (!deviceId || process.env.NODE_ENV === 'test') return;

  const record = deviceRateLimitStore.get(deviceId);
  if (record && record.blocked) {
    const err = new Error('This device has been blocked due to excessive OTP requests. Use password login instead.');
    err.status = 403;
    err.code = 'DEVICE_BLOCKED';
    throw err;
  }
}

function recordDeviceOtpRequest(deviceId) {
  if (!deviceId) return;

  const record = deviceRateLimitStore.get(deviceId) || { count: 0, blocked: false };
  record.count += 1;
  if (record.count >= 6) {
    record.blocked = true;
    console.warn(`[DEVICE BLOCKED] deviceId=${deviceId} exceeded 6 OTP requests — blocked.`);
  }
  deviceRateLimitStore.set(deviceId, record);
}

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

  // 0. Enforce device-level rate limit (block after 6 OTP requests from same device)
  checkDeviceRateLimit(options.deviceId);

  // 1. Enforce per-email rate limiting (60s cooldown, max 4 / 10m)
  checkOtpRateLimit(normalizedEmail);

  // 2. Only UIU degree-program emails are allowed (both registration and sign-in)
  if (!isUiuEmail(normalizedEmail)) {
    throw new Error('Only UIU student emails with degree program are allowed (e.g. ahamim2510370@bscse.uiu.ac.bd). Plain @uiu.ac.bd or other domains are not permitted.');
  }

  // 3. Check registration/sign-in specific rules
  if (options.isRegistration) {
    if (isEmailRegistered(normalizedEmail)) {
      const err = new Error('This account is already registered. Please sign in with your credentials.');
      err.status = 400;
      err.code = 'ALREADY_REGISTERED';
      err.alreadyRegistered = true;
      throw err;
    }

    if (options.password) {
      if (options.password.length < 6) {
        throw new Error('Password must be at least 6 characters long.');
      }
    }
  } else {
    if (!isEmailRegistered(normalizedEmail)) {
      const err = new Error('No account found for this email. Please register first.');
      err.status = 404;
      err.code = 'NOT_REGISTERED';
      err.notRegistered = true;
      throw err;
    }
  }

  recordOtpRequest(normalizedEmail);
  recordDeviceOtpRequest(options.deviceId);

  const otp = generate6DigitOtp();
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = hashOtp(otp, salt);
  const expiresAt = Date.now() + OTP_TTL_MS;

  let pendingPasswordHash = null;
  let pendingPasswordSalt = null;
  if (options.isRegistration && options.password) {
    const pw = hashPassword(options.password);
    pendingPasswordHash = pw.hash;
    pendingPasswordSalt = pw.salt;
  }

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
    pendingPasswordHash,
    pendingPasswordSalt,
  });

  // The shared HTTPS sender enforces its own request timeout.
  let emailResult = null;
  try {
    emailResult = await sendEmailOtp(normalizedEmail, otp);
    console.log(`✅ [EMAIL_API OK] Email accepted for ${normalizedEmail} | MessageId: ${emailResult.messageId}`);
  } catch (err) {
    console.error(`❌ [EMAIL_API DISPATCH FAILED] To: ${normalizedEmail}`);
    console.error(`   Error: ${err.message}`);
    console.error(`   err.code: ${err.code || 'none'}`);
    console.error(`   err.command: ${err.command || 'none'}`);
    console.error(`   err.responseCode: ${err.responseCode || 'none'}`);
    console.error(`   err.response: ${err.response || 'none'}`);
    console.error(`   Stack: ${err.stack}`);

    otpStore.delete(normalizedEmail);
    console.error(`   OTP removed from store — user must retry.`);

    const emailErr = new Error(`Email delivery failed: ${err.message}. Please try again in a moment.`);
    emailErr.status = 500;
    emailErr.code = 'EMAIL_API_FAILED';
    throw emailErr;
  }

  return {
    success: true,
    message: options.isRegistration
      ? 'A 6-digit registration code has been sent to your UIU email. Valid for 5 minutes.'
      : 'A 6-digit login verification code has been sent to your email. Valid for 5 minutes.',
    email: normalizedEmail,
    expiresInSeconds: 300,
    emailResult,
  };
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
  const pendingPasswordHash = record.pendingPasswordHash;
  const pendingPasswordSalt = record.pendingPasswordSalt;
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
    if (pendingPasswordHash && pendingPasswordSalt) {
      student.passwordHash = pendingPasswordHash;
      student.passwordSalt = pendingPasswordSalt;
    }
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

  const { passwordHash: _ph, passwordSalt: _ps, ...safeStudent } = student;
  return {
    success: true,
    message: isRegistration
      ? 'Registration complete! Welcome to Edutools UIU.'
      : 'Authenticated successfully with UIU Portal.',
    token,
    student: safeStudent,
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

/**
 * Authenticates a student using email + password (no OTP required)
 */
async function loginWithPassword(email, password) {
  const normalizedEmail = email.trim().toLowerCase();

  if (!isValidEmail(normalizedEmail)) {
    throw new Error('Please enter a valid email address.');
  }

  if (!password || password.length < 1) {
    throw new Error('Password is required.');
  }

  const student = studentStore.get(normalizedEmail);
  if (!student) {
    const err = new Error('No account found for this email. Please register first.');
    err.status = 404;
    err.code = 'NOT_REGISTERED';
    err.notRegistered = true;
    throw err;
  }

  if (!student.passwordHash || !student.passwordSalt) {
    const err = new Error('This account was created without a password. Please sign in using OTP verification.');
    err.status = 400;
    err.code = 'NO_PASSWORD';
    err.noPassword = true;
    throw err;
  }

  if (!verifyPassword(password, student.passwordHash, student.passwordSalt)) {
    throw new Error('Incorrect password. Please try again.');
  }

  student.lastLogin = new Date().toISOString();
  saveRegisteredStudents();

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

  const { passwordHash, passwordSalt, ...safeStudent } = student;
  return {
    success: true,
    message: 'Signed in successfully.',
    token,
    student: safeStudent,
  };
}


/**
 * Sets or updates a password for an existing student account.
 * Used by logged-in users who registered via OTP and never set a password.
 */
async function setPassword(email, newPassword) {
  const normalizedEmail = email.trim().toLowerCase();

  if (!isValidEmail(normalizedEmail)) {
    throw new Error('Please enter a valid email address.');
  }

  const student = studentStore.get(normalizedEmail);
  if (!student) {
    const err = new Error('No account found for this email.');
    err.status = 404;
    err.code = 'NOT_REGISTERED';
    throw err;
  }

  if (!newPassword || newPassword.length < 6) {
    throw new Error('Password must be at least 6 characters long.');
  }

  const pw = hashPassword(newPassword);
  student.passwordHash = pw.hash;
  student.passwordSalt = pw.salt;
  saveRegisteredStudents();

  return {
    success: true,
    message: 'Password set successfully. You can now sign in with your password.',
  };
}

/**
 * Checks whether a student account has a password set.
 */
function checkHasPassword(email) {
  const normalizedEmail = email.trim().toLowerCase();
  const student = studentStore.get(normalizedEmail);
  if (!student) return false;
  return !!(student.passwordHash && student.passwordSalt);
}

// ===================== EMAIL VERIFICATION WITH LINK (for Google Sign-In) =====================

/**
 * Generates a secure random token for email verification or password reset
 */
function generateSecureToken() {
  return crypto.randomBytes(32).toString('hex');
}

/**
 * Sends an email verification link to the user's email.
 * Used after Google Sign-In to verify ownership of the email address.
 */
async function sendVerificationEmail(email, token) {
  const norm = email.trim().toLowerCase();
  const verifyUrl = `${BACKEND_URL}/api/auth/verify-email?token=${token}`;

  const mailOptions = {
    from: { name: 'Edutools UIU Academic Portal', email: EMAIL_FROM },
    to: norm,
    replyTo: EMAIL_FROM,
    subject: 'Edutools UIU - Verify Your Email Address',
    text: `Welcome to Edutools (United International University)!\n\nClick the link below to verify your email address:\n${verifyUrl}\n\nThis link will expire in 15 minutes.\nIf you did not request this, please ignore this email.`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 24px; border: 1px solid #fed7aa; border-radius: 16px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #ea580c; margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px;">Edutools &bull; UIU</h1>
          <p style="color: #64748b; font-size: 13px; margin: 4px 0 0 0;">United International University Academic Calendar & Routine Sync</p>
        </div>
        <div style="background: #fff7ed; border: 1px solid #fdba74; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 20px;">
          <p style="color: #334155; font-size: 14px; margin: 0 0 16px 0;">Verify your email address <strong>${norm}</strong> to complete sign-in:</p>
          <a href="${verifyUrl}" style="display: inline-block; background: #ea580c; color: #ffffff; font-size: 16px; font-weight: 700; padding: 14px 32px; border-radius: 10px; text-decoration: none; letter-spacing: 0.5px;">
            Verify Email Address
          </a>
          <p style="color: #ef4444; font-size: 12px; margin: 16px 0 0 0; font-weight: 600;">⏱ Valid for 15 minutes only</p>
        </div>
        <p style="color: #64748b; font-size: 11px; line-height: 1.5; margin: 0; text-align: center;">
          Or copy and paste this link into your browser:<br/>
          <a href="${verifyUrl}" style="color: #2563eb; word-break: break-all;">${verifyUrl}</a>
        </p>
        <p style="color: #94a3b8; font-size: 11px; line-height: 1.5; margin: 12px 0 0 0; text-align: center;">
          Sent from <strong>${EMAIL_FROM}</strong>.<br/>
          If you did not request this, you can safely ignore this email.
        </p>
      </div>
    `,
  };

  // Suppress delivery only in explicit test mode.
  if (process.env.NODE_ENV === 'test') {
    console.log(`[TEST/DEV] Mock verification email to ${norm}. Link: ${verifyUrl}`);
    return { delivered: true, messageId: 'mock-verify-id', timestamp: new Date().toISOString() };
  }

  console.log(`📧 [DISPATCHING VERIFICATION EMAIL] To: ${norm}`);

  const info = await emailService.sendEmail(mailOptions);

  console.log(`✅ [VERIFICATION EMAIL ACCEPTED] MessageId: ${info.messageId}`);
  return { delivered: true, messageId: info.messageId, timestamp: new Date().toISOString() };
}

/**
 * Initiates email verification via link.
 * Supports Google Sign-In, sign-in (existing users), and registration (new users).
 * options.isRegistration — if true, validates not-already-registered, stores pending registration data
 * options.isSignIn — if true, validates already-registered
 * options.fullName, studentId, department, semester, password — registration fields
 */
async function requestEmailVerification(email, displayName, options = {}) {
  const normalizedEmail = email.trim().toLowerCase();

  if (!isValidEmail(normalizedEmail)) {
    throw new Error('Please enter a valid email address.');
  }

  if (options.isRegistration) {
    if (!isUiuEmail(normalizedEmail)) {
      throw new Error('Only UIU student emails with degree program are allowed (e.g. student@bscse.uiu.ac.bd).');
    }
    if (isEmailRegistered(normalizedEmail)) {
      const err = new Error('This account is already registered. Please sign in instead.');
      err.status = 400;
      err.code = 'ALREADY_REGISTERED';
      err.alreadyRegistered = true;
      throw err;
    }
    if (options.password && options.password.length < 6) {
      throw new Error('Password must be at least 6 characters long.');
    }
  }

  if (options.isSignIn) {
    if (!isUiuEmail(normalizedEmail)) {
      throw new Error('Only UIU student emails with degree program are allowed (e.g. student@bscse.uiu.ac.bd).');
    }
    if (!isEmailRegistered(normalizedEmail)) {
      const err = new Error('No account found for this email. Please register first.');
      err.status = 404;
      err.code = 'NOT_REGISTERED';
      err.notRegistered = true;
      throw err;
    }
  }

  let pendingPasswordHash = null;
  let pendingPasswordSalt = null;
  if (options.isRegistration && options.password) {
    const pw = hashPassword(options.password);
    pendingPasswordHash = pw.hash;
    pendingPasswordSalt = pw.salt;
  }

  const token = generateSecureToken();
  const expiresAt = Date.now() + VERIFICATION_TTL_MS;

  emailVerificationStore.set(token, {
    email: normalizedEmail,
    expiresAt,
    verified: false,
    displayName: displayName || formatNameFromEmail(normalizedEmail),
    isRegistration: !!options.isRegistration,
    isSignIn: !!options.isSignIn,
    fullName: options.fullName?.trim(),
    studentId: options.studentId?.trim(),
    department: options.department?.trim(),
    semester: options.semester?.trim(),
    pendingPasswordHash,
    pendingPasswordSalt,
  });

  // Clear any previous verified status for this email so user must re-verify
  emailVerifiedSet.delete(normalizedEmail);

  try {
    await sendVerificationEmail(normalizedEmail, token);
  } catch (err) {
    emailVerificationStore.delete(token);
    const emailErr = new Error(`Failed to send verification email: ${err.message}. Please try again.`);
    emailErr.status = 500;
    emailErr.code = 'EMAIL_API_FAILED';
    throw emailErr;
  }

  return {
    success: true,
    message: 'A verification link has been sent to your email. Please check your inbox and click the link to verify.',
    email: normalizedEmail,
    expiresInSeconds: VERIFICATION_TTL_MS / 1000,
  };
}

/**
 * Verifies an email verification token (called when user clicks the link).
 * Returns an HTML page confirming verification.
 */
function verifyEmailToken(token) {
  const record = emailVerificationStore.get(token);

  if (!record) {
    return { success: false, error: 'Invalid or expired verification link.' };
  }

  if (Date.now() > record.expiresAt) {
    emailVerificationStore.delete(token);
    return { success: false, error: 'This verification link has expired. Please request a new one.' };
  }

  // Mark as verified
  record.verified = true;
  emailVerifiedSet.set(record.email, {
    verified: true,
    displayName: record.displayName,
    verifiedAt: new Date().toISOString(),
  });

  // Create or update student record
  const domain = record.email.split('@')[1];
  let student = studentStore.get(record.email);
  if (!student || record.isRegistration) {
    student = {
      id: student ? student.id : `STD-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      studentId: record.studentId || (student ? student.studentId : record.email.split('@')[0].toUpperCase()),
      fullName: record.fullName || record.displayName || (student ? student.fullName : record.email.split('@')[0]),
      email: record.email,
      department: record.department || (student ? student.department : inferDepartmentFromDomain(domain)),
      semester: record.semester || (student ? student.semester : 'Spring 2026'),
      university: extractUniversityName(domain),
      domain,
      createdAt: student ? student.createdAt : new Date().toISOString(),
      lastLogin: new Date().toISOString(),
      emailVerified: true,
    };
    if (record.pendingPasswordHash && record.pendingPasswordSalt) {
      student.passwordHash = record.pendingPasswordHash;
      student.passwordSalt = record.pendingPasswordSalt;
    }
    studentStore.set(record.email, student);
  } else {
    student.lastLogin = new Date().toISOString();
    student.emailVerified = true;
  }
  saveRegisteredStudents();

  // Clean up used token after a delay (keep for a bit so check-verification can find it)
  setTimeout(() => emailVerificationStore.delete(token), 60000);

  return { success: true, email: record.email, displayName: record.displayName };
}

/**
 * Checks if an email has been verified (polled by the frontend after sending verification link).
 * Returns verified status and a JWT token if verified.
 */
function checkEmailVerification(email) {
  const normalizedEmail = email.trim().toLowerCase();
  const verifiedRecord = emailVerifiedSet.get(normalizedEmail);

  if (!verifiedRecord || !verifiedRecord.verified) {
    return { verified: false };
  }

  // Issue JWT token
  const student = studentStore.get(normalizedEmail);
  if (!student) {
    return { verified: false };
  }

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

  const { passwordHash: _ph, passwordSalt: _ps, ...safeStudent } = student;

  // Clear the verified set entry (single use)
  emailVerifiedSet.delete(normalizedEmail);

  return {
    verified: true,
    token,
    student: safeStudent,
  };
}

// ===================== PASSWORD RESET =====================

/**
 * Sends a password reset email with a link.
 */
async function sendPasswordResetEmail(email, token) {
  const norm = email.trim().toLowerCase();
  const resetUrl = `${BACKEND_URL}/api/auth/reset-password?token=${token}`;

  const mailOptions = {
    from: { name: 'Edutools UIU Academic Portal', email: EMAIL_FROM },
    to: norm,
    replyTo: EMAIL_FROM,
    subject: 'Edutools UIU - Reset Your Password',
    text: `You requested a password reset for your Edutools account.\n\nClick the link below to set a new password:\n${resetUrl}\n\nThis link will expire in 15 minutes.\nIf you did not request this, please ignore this email.`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 24px; border: 1px solid #fed7aa; border-radius: 16px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #ea580c; margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px;">Edutools &bull; UIU</h1>
          <p style="color: #64748b; font-size: 13px; margin: 4px 0 0 0;">Password Reset Request</p>
        </div>
        <div style="background: #fff7ed; border: 1px solid #fdba74; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 20px;">
          <p style="color: #334155; font-size: 14px; margin: 0 0 16px 0;">Click the button below to reset your password for <strong>${norm}</strong>:</p>
          <a href="${resetUrl}" style="display: inline-block; background: #ea580c; color: #ffffff; font-size: 16px; font-weight: 700; padding: 14px 32px; border-radius: 10px; text-decoration: none; letter-spacing: 0.5px;">
            Reset Password
          </a>
          <p style="color: #ef4444; font-size: 12px; margin: 16px 0 0 0; font-weight: 600;">⏱ Valid for 15 minutes only</p>
        </div>
        <p style="color: #64748b; font-size: 11px; line-height: 1.5; margin: 0; text-align: center;">
          Or copy and paste this link into your browser:<br/>
          <a href="${resetUrl}" style="color: #2563eb; word-break: break-all;">${resetUrl}</a>
        </p>
        <p style="color: #94a3b8; font-size: 11px; line-height: 1.5; margin: 12px 0 0 0; text-align: center;">
          If you did not request a password reset, you can safely ignore this email.
        </p>
      </div>
    `,
  };

  // Suppress delivery only in explicit test mode.
  if (process.env.NODE_ENV === 'test') {
    console.log(`[TEST/DEV] Mock reset email to ${norm}. Link: ${resetUrl}`);
    return { delivered: true, messageId: 'mock-reset-id' };
  }

  console.log(`📧 [DISPATCHING PASSWORD RESET EMAIL] To: ${norm}`);

  const info = await emailService.sendEmail(mailOptions);

  console.log(`✅ [RESET EMAIL ACCEPTED] MessageId: ${info.messageId}`);
  return { delivered: true, messageId: info.messageId };
}

/**
 * Initiates a password reset flow by sending a reset link email.
 */
async function requestPasswordReset(email) {
  const normalizedEmail = email.trim().toLowerCase();

  if (!isValidEmail(normalizedEmail)) {
    throw new Error('Please enter a valid email address.');
  }

  const student = studentStore.get(normalizedEmail);
  if (!student) {
    // Don't reveal whether the account exists — always return success
    return {
      success: true,
      message: 'If an account exists with this email, a password reset link has been sent.',
    };
  }

  const token = generateSecureToken();
  const expiresAt = Date.now() + RESET_TTL_MS;

  passwordResetStore.set(token, {
    email: normalizedEmail,
    expiresAt,
    used: false,
  });

  try {
    await sendPasswordResetEmail(normalizedEmail, token);
  } catch (err) {
    passwordResetStore.delete(token);
    console.error(`❌ [RESET EMAIL FAILED] ${err.message}`);
    // Still return success to avoid email enumeration
  }

  return {
    success: true,
    message: 'If an account exists with this email, a password reset link has been sent.',
  };
}

/**
 * Validates a password reset token (for rendering the reset form).
 */
function validateResetToken(token) {
  const record = passwordResetStore.get(token);
  if (!record) {
    return { valid: false, error: 'Invalid or expired reset link.' };
  }
  if (Date.now() > record.expiresAt) {
    passwordResetStore.delete(token);
    return { valid: false, error: 'This reset link has expired. Please request a new one.' };
  }
  if (record.used) {
    return { valid: false, error: 'This reset link has already been used.' };
  }
  return { valid: true, email: record.email };
}

/**
 * Resets password using a valid reset token.
 */
function resetPasswordWithToken(token, newPassword) {
  const record = passwordResetStore.get(token);
  if (!record) {
    throw new Error('Invalid or expired reset link.');
  }
  if (Date.now() > record.expiresAt) {
    passwordResetStore.delete(token);
    throw new Error('This reset link has expired. Please request a new one.');
  }
  if (record.used) {
    throw new Error('This reset link has already been used.');
  }
  if (!newPassword || newPassword.length < 6) {
    throw new Error('Password must be at least 6 characters long.');
  }

  const student = studentStore.get(record.email);
  if (!student) {
    throw new Error('Account not found.');
  }

  const pw = hashPassword(newPassword);
  student.passwordHash = pw.hash;
  student.passwordSalt = pw.salt;
  saveRegisteredStudents();

  record.used = true;
  // Clean up after a delay
  setTimeout(() => passwordResetStore.delete(token), 60000);

  return {
    success: true,
    message: 'Password has been reset successfully. You can now sign in with your new password.',
  };
}

module.exports = {
  isValidEmail,
  isUiuEmail,
  isUniversityEmail,
  isEmailRegistered,
  requestOtp,
  verifyOtp,
  loginWithPassword,
  setPassword,
  checkHasPassword,
  verifySessionToken,
  getEmailStatus: emailService.getEmailStatus,
  formatNameFromEmail,
  studentStore,
  otpStore,
  saveRegisteredStudents,
  // Email verification (Google Sign-In)
  requestEmailVerification,
  verifyEmailToken,
  checkEmailVerification,
  // Password reset
  requestPasswordReset,
  validateResetToken,
  resetPasswordWithToken,
};
