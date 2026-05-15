const User = require('../models/User');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

exports.registerUser = async (req, res) => {
  try {
    const { name, email, password, role, fcmToken } = req.body;
    const userExists = await User.findOne({ email });
    if (userExists) return res.status(400).json({ message: "User already exists" });
    const user = await User.create({ name, email, password, role, fcmToken });
    res.status(201).json({ _id: user._id, name: user.name, role: user.role, token: generateToken(user._id) });
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
    const { name, bio } = req.body;
    const updateData = {};
    if (name) updateData.name = name;
    if (bio) updateData.bio = bio;
    if (req.file) updateData.avatar = req.file.path; // Cloudinary URL

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