require('dotenv').config({ path: require('path').join(__dirname, '.env') });
const mongoose = require('mongoose');
let connectionAttempt = null;

async function connectDB() {
  if (isConnected()) return true;
  if (connectionAttempt) return connectionAttempt;
  connectionAttempt = (async () => {
    try {
      await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/edutools', {
        serverSelectionTimeoutMS: 5000, connectTimeoutMS: 5000,
      });
      console.log('[MongoDB] Connected.');
      return true;
    } catch (error) {
      console.error('[MongoDB] Connection unavailable:', error.name, error.code || '');
      return false;
    }
  })();
  try { return await connectionAttempt; }
  finally { connectionAttempt = null; }
}

function isConnected() {
  return mongoose.connection.readyState === 1;
}

module.exports = { connectDB, isConnected };
