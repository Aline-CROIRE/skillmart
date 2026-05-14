const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getProfile, depositBalance, updateProfile, verifyEmail, resendVerification } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');
const cloudinaryUpload = require('../config/cloudinary');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.post('/resend-verification', resendVerification);
router.get('/verify/:token', verifyEmail);
router.get('/profile', protect, getProfile); // RESTORED
router.patch('/profile', protect, cloudinaryUpload.single('avatar'), updateProfile);
router.patch('/deposit', protect, depositBalance);

module.exports = router;