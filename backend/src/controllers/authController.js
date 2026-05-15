const crypto = require('crypto');
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../services/emailService');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

exports.registerUser = async (req, res) => {
  try {
    const { name, email, password, role, fcmToken } = req.body;
    const userExists = await User.findOne({ email });
    if (userExists) return res.status(400).json({ message: "User already exists" });

    // Create user
    const user = await User.create({ name, email, password, role, fcmToken });

    // AUTOMATION: Send verification email immediately
    const code = String(crypto.randomInt(100000, 1000000));
    user.emailVerificationCode = code;
    user.emailVerificationExpires = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    // Trigger email (don't await to avoid blocking response, or await if you want to ensure delivery)
    sendVerificationEmail(user.email, user.name, code).catch(err => 
      console.error('Initial verification email failed:', err)
    );

    res.status(201).json({ 
      _id: user._id, 
      name: user.name, 
      role: user.role, 
      token: generateToken(user._id),
      message: "Registration successful. Verification email sent." 
    });
  } catch (error) { res.status(500).json({ message: error.message }); }
};

exports.loginUser = async (req, res) => {
  try {
    const { email, password, fcmToken } = req.body;
    const user = await User.findOne({ email });
    if (user && (await user.matchPassword(password))) {
      if (fcmToken) {
        user.fcmToken = fcmToken;
        await user.save();
      }
      res.json({ _id: user._id, name: user.name, role: user.role, walletBalance: user.walletBalance, token: generateToken(user._id) });
    } else { res.status(401).json({ message: "Invalid email or password" }); }
  } catch (error) { res.status(500).json({ message: error.message }); }
};

// RESTORED: Profile route
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .select('-password')
      .populate('purchasedProjects')
      .populate('bookmarkedProjects');
    res.json(user);
  } catch (error) { res.status(500).json({ message: error.message }); }
};

exports.depositBalance = async (req, res) => {
  try {
    const amount = Number(req.body.amount);
    if (amount > 100000) return res.status(400).json({ message: "Limit RWF 100,000 exceeded" });
    const user = await User.findByIdAndUpdate(req.user._id, { $inc: { walletBalance: amount } }, { new: true });
    res.json(user);
  } catch (error) { res.status(500).json({ message: error.message }); }
};

exports.updateProfile = async (req, res) => {
  try {
    const updateData = {};
    if (req.file) updateData.avatar = req.file.path;

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ message: 'No avatar file provided' });
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updateData },
      { new: true }
    ).select('-password');

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateProfileInfo = async (req, res) => {
  try {
    const { name, bio, email } = req.body;
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (name !== undefined) {
      const trimmed = String(name).trim();
      if (!trimmed) return res.status(400).json({ message: 'Name cannot be empty' });
      user.name = trimmed;
    }

    if (bio !== undefined) {
      user.bio = String(bio).trim();
    }

    if (email !== undefined) {
      const trimmedEmail = String(email).trim().toLowerCase();
      if (!trimmedEmail) return res.status(400).json({ message: 'Email cannot be empty' });
      if (trimmedEmail !== user.email) {
        const existing = await User.findOne({ email: trimmedEmail });
        if (existing) return res.status(400).json({ message: 'Email is already in use' });
        user.email = trimmedEmail;
        user.emailVerified = false;
        user.emailVerificationCode = undefined;
        user.emailVerificationExpires = undefined;
      }
    }

    await user.save();
    const updated = await User.findById(user._id).select('-password');
    res.json(updated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.sendEmailVerification = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('+emailVerificationCode +emailVerificationExpires');
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (user.emailVerified) {
      return res.status(400).json({ message: 'Email is already verified' });
    }

    const code = String(crypto.randomInt(100000, 1000000));
    user.emailVerificationCode = code;
    user.emailVerificationExpires = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    const result = await sendVerificationEmail(user.email, user.name, code);
    if (!result.ok) {
      const hint = process.env.RESEND_API_KEY
        ? ''
        : ' Set RESEND_API_KEY on the server for reliable delivery from cloud hosting.';
      return res.status(500).json({
        message: `Failed to send verification email.${hint}`,
        detail: process.env.NODE_ENV === 'production' ? undefined : result.error,
      });
    }

    res.json({ message: 'Verification code sent to your email' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.verifyEmail = async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) return res.status(400).json({ message: 'Verification code is required' });

    const user = await User.findById(req.user._id).select('+emailVerificationCode +emailVerificationExpires');
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (user.emailVerified) {
      return res.json({ message: 'Email is already verified', emailVerified: true });
    }

    if (!user.emailVerificationCode || !user.emailVerificationExpires) {
      return res.status(400).json({ message: 'No verification code found. Request a new one.' });
    }

    if (user.emailVerificationExpires < new Date()) {
      return res.status(400).json({ message: 'Verification code has expired. Request a new one.' });
    }

    if (String(code).trim() !== user.emailVerificationCode) {
      return res.status(400).json({ message: 'Invalid verification code' });
    }

    user.emailVerified = true;
    user.emailVerificationCode = undefined;
    user.emailVerificationExpires = undefined;
    await user.save();

    const updated = await User.findById(user._id).select('-password');
    res.json({ message: 'Email verified successfully', emailVerified: true, user: updated });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const user = await User.findById(req.user._id).select('+password');
    
    if (!(await user.matchPassword(oldPassword))) {
      return res.status(401).json({ message: 'Current password incorrect' });
    }

    user.password = newPassword;
    await user.save();
    res.json({ message: 'Password updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const code = String(crypto.randomInt(100000, 1000000));
    user.resetPasswordCode = code;
    user.resetPasswordExpires = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    await sendPasswordResetEmail(user.email, user.name, code);
    res.json({ message: 'Recovery code sent to your email' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    const user = await User.findOne({ email }).select('+resetPasswordCode +resetPasswordExpires');
    
    if (!user || user.resetPasswordCode !== String(code).trim()) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }

    if (user.resetPasswordExpires < new Date()) {
      return res.status(400).json({ message: 'Code has expired' });
    }

    user.password = newPassword;
    user.resetPasswordCode = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    res.json({ message: 'Password reset successful. You can now login.' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};