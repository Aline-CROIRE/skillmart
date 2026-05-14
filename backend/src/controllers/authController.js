const User = require('../models/User');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

exports.registerUser = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    const userExists = await User.findOne({ email });
    if (userExists) return res.status(400).json({ message: "User already exists" });

    const user = await User.create({ name, email, password, role });
    res.status(201).json({
      _id: user._id,
      name: user.name,
      role: user.role,
      token: generateToken(user._id),
    });
  } catch (error) { res.status(500).json({ message: error.message }); }
};

exports.loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (user && (await user.matchPassword(password))) {
      res.json({
        _id: user._id,
        name: user.name,
        role: user.role,
        walletBalance: user.walletBalance,
        token: generateToken(user._id),
      });
    } else {
      res.status(401).json({ message: "Invalid email or password" });
    }
  } catch (error) { res.status(500).json({ message: error.message }); }
};

// 💰 UPDATED: Deposit with RWF 100,000 Limit
exports.depositBalance = async (req, res) => {
  try {
    const { amount } = req.body;
    const depositAmount = Number(amount);

    if (!depositAmount || depositAmount <= 0) {
      return res.status(400).json({ message: "Please enter a valid amount." });
    }

    if (depositAmount > 100000) {
      return res.status(400).json({ 
        message: "For community safety, the maximum top-up limit is RWF 100,000." 
      });
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { $inc: { walletBalance: depositAmount } },
      { new: true }
    ).select('-password');

    res.json({ message: `Successfully added RWF ${depositAmount}`, user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};