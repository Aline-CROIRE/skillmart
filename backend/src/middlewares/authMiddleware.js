const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = await User.findById(decoded.id).select('-password');

      // Check if account is paused
      if (req.user && req.user.isPaused) {
        if (req.user.pausedUntil && new Date() > req.user.pausedUntil) {
          // Pause expired, unpause automatically
          req.user.isPaused = false;
          req.user.pausedUntil = null;
          await req.user.save();
        } else {
          return res.status(403).json({ 
            message: 'Your account is currently suspended. Please contact admin.',
            isPaused: true,
            pausedUntil: req.user.pausedUntil
          });
        }
      }

      next();
    } catch (error) {
      res.status(401).json({ message: 'Not authorized, token failed' });
    }
  } else {
    res.status(401).json({ message: 'No token, authorization denied' });
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        message: `User role ${req.user.role} is not authorized to access this route` 
      });
    }
    next();
  };
};

const isConfirmedAnalyst = (req, res, next) => {
  if (req.user.role === 'Analyst') {
    if (!req.user.emailVerified) {
      return res.status(403).json({ 
        message: 'Please verify your email address to access the Review Hub.',
        needsVerification: true
      });
    }
    if (!req.user.isProfileConfirmed) {
      return res.status(403).json({ 
        message: 'Your profile is awaiting Admin confirmation. Please ensure your National ID and Picture are uploaded.',
        needsConfirmation: true
      });
    }
  }
  next();
};

module.exports = { protect, authorize, isConfirmedAnalyst };