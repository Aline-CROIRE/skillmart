const User = require('../models/User');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { sendVerificationEmail } = require('../services/emailService');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

exports.registerUser = async (req, res) => {
  try {
    const { name, email, password, role, fcmToken, phoneNumber } = req.body;
    const userExists = await User.findOne({ email });
    if (userExists) return res.status(400).json({ message: "User already exists" });
    
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const user = await User.create({ name, email, password, role, fcmToken, phoneNumber, verificationToken });
    
    await sendVerificationEmail(email, verificationToken);
    
    res.status(201).json({ message: "Registration successful. Please check your email to verify your account." });
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

exports.verifyEmail = async (req, res) => {
  try {
    const user = await User.findOne({ verificationToken: req.params.token });
    if (!user) return res.status(400).send("<h1>Verification Failed</h1><p>Invalid or expired token.</p>");
    
    // If it was an email change
    if (user.newEmail) {
      if (user.email) user.emailHistory.push(user.email);
      user.email = user.newEmail;
      user.newEmail = undefined;
    }

    user.isVerified = true;
    user.verificationToken = undefined;
    await user.save();
    
    res.send("<h1>Verification Successful</h1><p>Your email has been verified. You can now log in through the app.</p>");
  } catch (error) { res.status(500).send("<h1>Server Error</h1>"); }
};

exports.resendVerification = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });
    if (user.isVerified) return res.status(400).json({ message: "Account already verified" });

    const verificationToken = crypto.randomBytes(32).toString('hex');
    user.verificationToken = verificationToken;
    await user.save();

    await sendVerificationEmail(email, verificationToken);
    res.json({ message: "Verification email resent. Please check your inbox." });
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
    const { name, bio, email, phoneNumber } = req.body;
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: "User not found" });

    if (name) user.name = name;
    if (bio) user.bio = bio;
    if (req.file) user.avatar = req.file.path;

    if (phoneNumber && phoneNumber !== user.phoneNumber) {
      if (user.phoneNumber) user.phoneHistory.push(user.phoneNumber);
      user.phoneNumber = phoneNumber;
    }

    let verificationSent = false;
    if (email && email !== user.email) {
      // Check if email taken
      const emailTaken = await User.findOne({ email });
      if (emailTaken) return res.status(400).json({ message: "Email already in use" });

      user.newEmail = email;
      user.isVerified = false;
      const token = crypto.randomBytes(32).toString('hex');
      user.verificationToken = token;
      await sendVerificationEmail(email, token);
      verificationSent = true;
    }

    await user.save();
    
    const responseUser = user.toObject();
    delete responseUser.password;
    
    res.json({ 
      user: responseUser, 
      message: verificationSent ? "Profile updated. Please verify your new email address." : "Profile updated successfully" 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};