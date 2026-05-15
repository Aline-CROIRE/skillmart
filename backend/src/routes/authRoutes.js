const express = require('express');
const router = express.Router();
const {
  registerUser,
  loginUser,
  getProfile,
  depositBalance,
  updateProfile,
  updateProfileInfo,
  sendEmailVerification,
  verifyEmail,
  changePassword,
  forgotPassword,
  resetPassword,
} = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');
const cloudinaryUpload = require('../config/cloudinary');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/profile', protect, getProfile); // RESTORED
router.patch('/profile', protect, cloudinaryUpload.single('avatar'), updateProfile);
router.patch('/profile/info', protect, updateProfileInfo);
router.post('/verify-email/send', protect, sendEmailVerification);
router.post('/verify-email', protect, verifyEmail);
router.patch('/deposit', protect, depositBalance);

// Password Management
router.post('/change-password', protect, changePassword);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

module.exports = router;