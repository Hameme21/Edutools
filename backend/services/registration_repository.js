const db = require('../db');
const RegisteredStudent = require('../models/RegisteredStudent');
const StudentSchedule = require('../models/StudentSchedule');
const DEPARTMENTS = ['CSE', 'DS', 'BBA', 'CE', 'EDS', 'EEE', 'BSE'];

class RegistrationStoreError extends Error {
  constructor() {
    super('Registration storage is temporarily unavailable. Please try again shortly; you do not need to register again.');
    this.status = 503;
    this.code = 'REGISTRATION_STORE_UNAVAILABLE';
  }
}

async function ready() {
  if (!db.isConnected()) await db.connectDB();
  if (!db.isConnected()) throw new RegistrationStoreError();
}

async function storedRecord(identity) {
  // Prefer the stable Firebase identity, then support older email-only records.
  return await RegisteredStudent.findOne({ firebaseUid: identity.uid }).lean() ||
    await RegisteredStudent.findOne({ email: identity.email }).lean();
}

function legacyProfile(record, identity) {
  const profile = record?.student;
  if (!profile || profile.registrationComplete === false) return null;
  if (profile.email && profile.email.trim().toLowerCase() !== identity.email) return null;
  const aliases = {
    'Computer Science & Engineering': 'CSE', 'Data Science': 'DS',
    'Business Administration': 'BBA', 'School of Business & Economics': 'BBA',
    'Civil Engineering': 'CE', 'Electrical & Electronic Engineering': 'EEE',
    'Environment & Development Studies': 'EDS', 'Environment and Development Studies': 'EDS',
  };
  const department = aliases[profile.department] || profile.department;
  if (typeof profile.fullName !== 'string' || !profile.fullName.trim() ||
      typeof profile.studentId !== 'string' || !profile.studentId.trim() || !DEPARTMENTS.includes(department)) return null;
  return { ...profile, email: identity.email, department, registrationComplete: true,
    emailVerified: true, id: profile.id || `STD-${identity.uid}` };
}

async function find(identity) {
  await ready();
  const record = await storedRecord(identity);
  if (record?.profile) return record.profile;
  // Older web/mobile releases saved completed profiles with the routine only.
  return legacyProfile(await StudentSchedule.findOne({ email: identity.email }).lean(), identity);
}

async function save(identity, profile) {
  await ready();
  const existing = await storedRecord(identity);
  await RegisteredStudent.findOneAndUpdate(
    existing ? { _id: existing._id } : { email: identity.email },
    { $set: { email: identity.email, firebaseUid: identity.uid, profile } },
    { upsert: true, new: true, runValidators: true },
  );
}

module.exports = { find, save, legacyProfile, RegistrationStoreError, DEPARTMENTS };
