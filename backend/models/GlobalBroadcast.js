const mongoose = require('mongoose');

const globalBroadcastSchema = new mongoose.Schema({
  key: { type: String, default: 'global', unique: true },
  version: { type: Number, default: 0 },
  source: { type: String, default: 'Official Academic Server' },
  notices: { type: [mongoose.Schema.Types.Mixed], default: [] },
  classes: { type: [mongoose.Schema.Types.Mixed], default: [] },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('GlobalBroadcast', globalBroadcastSchema);
