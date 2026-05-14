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
  fcmToken: { type: String },
  phoneNumber: { type: String },
  newEmail: { type: String }, // For email change verification
  isVerified: { type: Boolean, default: false },
  verificationToken: { type: String },
  emailHistory: [String],
  phoneHistory: [String],
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