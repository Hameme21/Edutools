const mongoose = require('mongoose');

const studentScheduleSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  student: { type: mongoose.Schema.Types.Mixed, default: null },
  classes: { type: [mongoose.Schema.Types.Mixed], default: [] },
  updatedAt: { type: Date, default: Date.now },
}, { timestamps: true });

module.exports = mongoose.model('StudentSchedule', studentScheduleSchema);
