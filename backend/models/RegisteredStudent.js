const mongoose = require('mongoose');
module.exports = mongoose.model('RegisteredStudent', new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  firebaseUid: { type: String, index: true, sparse: true },
  profile: { type: mongoose.Schema.Types.Mixed, required: true },
}, { timestamps: true }));
