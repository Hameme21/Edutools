const mongoose = require('mongoose');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/edutools';

let connected = false;

async function connectDB() {
  if (connected) return;
  try {
    await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 5000, connectTimeoutMS: 5000 });
    connected = true;
    console.log('[MongoDB] Connected to', MONGO_URI.replace(/\/\/[^:]+:[^@]+@/, '//***:***@'));
  } catch (err) {
    console.error('[MongoDB] Connection failed:', err.message);
    console.warn('[MongoDB] Falling back to in-memory storage.');
  }
}

function isConnected() {
  return mongoose.connection.readyState === 1;
}

module.exports = { connectDB, isConnected };
