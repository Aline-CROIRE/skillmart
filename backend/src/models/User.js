const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { 
    type: String, 
    enum: ['Guest', 'User', 'Analyst', 'Admin'], 
    default: 'User' 
  },
  walletBalance: { type: Number, default: 0 },
  bio: { type: String },
  avatar: { type: String },
  emailVerified: { type: Boolean, default: false },
  emailVerificationCode: { type: String, select: false },
  emailVerificationExpires: { type: Date, select: false },
  fcmToken: { type: String },
  resetPasswordCode: { type: String, select: false },
  resetPasswordExpires: { type: Date, select: false },
  isPaused: { type: Boolean, default: false },
  pausedUntil: { type: Date },
  isProfileConfirmed: { type: Boolean, default: false },
  nationalIdUrl: { type: String },
  verificationSelfieUrl: { type: String },
  purchasedProjects: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Project' }],
  bookmarkedProjects: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Project' }]
}, { timestamps: true });

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
});

userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);