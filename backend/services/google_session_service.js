const jwt = require('jsonwebtoken');
const auth = require('./auth_service');
const crypto = require('node:crypto');
const registrations = require('./registration_repository');
const { DEPARTMENTS, RegistrationStoreError } = registrations;
const projectId = process.env.FIREBASE_PROJECT_ID || 'edutools-e2558';
let cachedCertificates, certificatesExpireAt = 0;

async function verifyGoogleIdentity(idToken, fetchImpl = fetch) {
  if (typeof idToken !== 'string' || idToken.length > 16000) throw new Error('A Firebase sign-in token is required.');
  const decoded = jwt.decode(idToken, { complete: true });
  if (!decoded || decoded.header.alg !== 'RS256' || !decoded.header.kid) throw new Error('Invalid Firebase sign-in token.');
  if (!cachedCertificates || Date.now() >= certificatesExpireAt || !Object.hasOwn(cachedCertificates, decoded.header.kid)) {
    const response = await fetchImpl('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com', { signal: AbortSignal.timeout(10000) });
    if (!response.ok) throw new Error('Could not verify Google sign-in. Please retry.');
    cachedCertificates = await response.json();
    const maxAge = Number(response.headers.get('cache-control')?.match(/max-age=(\d+)/)?.[1] || 300);
    certificatesExpireAt = Date.now() + Math.min(maxAge, 3600) * 1000;
  }
  const key = cachedCertificates[decoded.header.kid];
  if (!key) throw new Error('Google signing certificate was not recognized. Please retry.');
  const claims = jwt.verify(idToken, key, { algorithms: ['RS256'], audience: projectId, issuer: `https://securetoken.google.com/${projectId}` });
  const now = Math.floor(Date.now() / 1000);
  if (typeof claims.sub !== 'string' || !claims.sub || claims.sub.length > 128 || typeof claims.email !== 'string' || !auth.isValidEmail(claims.email) || claims.email_verified !== true ||
      claims.firebase?.sign_in_provider !== 'google.com' || !Number.isFinite(claims.auth_time) || claims.auth_time > now ||
      !Number.isFinite(claims.iat) || claims.iat > now || !Number.isFinite(claims.exp)) {
    throw new Error('A verified Google account is required.');
  }
  return { email: claims.email.trim().toLowerCase(), uid: claims.sub, name: claims.name || '' };
}

async function registrationOperation(operation) {
  try { return await operation(); }
  catch (error) {
    console.warn('[REGISTRATION STORE]', error.name, error.code || '');
    throw error instanceof RegistrationStoreError ? error : new RegistrationStoreError();
  }
}

async function authenticate(idToken, registration, verify = verifyGoogleIdentity, store = registrations) {
  const identity = await verify(idToken);
  const cached = auth.studentStore.get(identity.email);
  const found = cached || await registrationOperation(() => store.find(identity));
  if (!found && !registration) return { success: true, requiresRegistration: true, email: identity.email, displayName: identity.name };
  let student = found ? { ...found } : null;
  if (!student) {
    const fullName = registration.fullName?.trim();
    const studentId = registration.studentId?.trim();
    const department = registration.department?.trim();
    if (!fullName || !studentId || !DEPARTMENTS.includes(department)) throw new Error('Name, student ID and a valid department are required.');
    if (registration.password && (typeof registration.password !== 'string' || registration.password.length < 6)) throw new Error('Password must be at least 6 characters.');
    student = { id: `STD-${identity.uid}`, email: identity.email, fullName, studentId, department,
      semester: registration.semester?.trim() || '', university: 'United International University',
      createdAt: new Date().toISOString(), emailVerified: true, registrationComplete: true };
    if (registration.password) {
      student.passwordSalt = crypto.randomBytes(32).toString('hex');
      student.passwordHash = crypto.pbkdf2Sync(registration.password, student.passwordSalt, 100000, 64, 'sha512').toString('hex');
    }
  }
  const previousEmail = student.email;
  student.email = identity.email;
  student.firebaseUid = identity.uid;
  student.registrationComplete = true;
  student.lastLogin = new Date().toISOString();
  student.emailVerified = true;
  // Do not grant a session or mark registration complete until storage acknowledges it.
  await registrationOperation(() => store.save(identity, student));
  if (previousEmail && previousEmail !== identity.email) auth.studentStore.delete(previousEmail);
  auth.studentStore.set(identity.email, student);
  auth.saveRegisteredStudents();
  const token = jwt.sign({ email: identity.email, studentId: student.studentId, fullName: student.fullName, university: student.university },
    process.env.JWT_SECRET || 'edutools-secure-jwt-secret-key-2026-academic', { expiresIn: '7d' });
  const { passwordHash, passwordSalt, ...safeStudent } = student;
  return { success: true, requiresRegistration: false, token, student: safeStudent };
}

module.exports = { authenticate, verifyGoogleIdentity, DEPARTMENTS };
