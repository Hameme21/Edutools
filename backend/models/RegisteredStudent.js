const mongoose = require('mongoose');
module.exports = mongoose.model('RegisteredStudent', new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  profile: { type: mongoose.Schema.Types.Mixed, required: true },
}, { timestamps: true }));
