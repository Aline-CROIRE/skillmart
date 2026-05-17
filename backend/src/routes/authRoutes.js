const express = require('express');
const router = express.Router();
const {
  registerUser,
  loginUser,
  getProfile,
  depositBalance,
  updateProfile,
  updateProfileInfo,
  updateNationalId,
  updateVerificationSelfie,
  sendEmailVerification,
  verifyEmail,
  changePassword,
  forgotPassword,
  resetPassword,
  logoutUser,
  submitFeedback,
} = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');
const { cloudinaryUpload } = require('../config/cloudinary');

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: User authentication and profile management
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, email, password]
 *             properties:
 *               name: { type: string }
 *               email: { type: string }
 *               password: { type: string }
 *     responses:
 *       201:
 *         description: User created successfully
 */
router.post('/register', registerUser);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Log in a user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string }
 *               password: { type: string }
 *     responses:
 *       200:
 *         description: Login successful
 */
router.post('/login', loginUser);
router.get('/profile', protect, getProfile); // RESTORED
router.patch('/profile', protect, cloudinaryUpload.single('avatar'), updateProfile);
router.patch('/profile/info', protect, updateProfileInfo);
router.patch('/profile/national-id', protect, cloudinaryUpload.single('nationalId'), updateNationalId);
router.patch('/profile/verification-selfie', protect, cloudinaryUpload.single('selfie'), updateVerificationSelfie);
router.post('/verify-email/send', protect, sendEmailVerification);
router.post('/verify-email', protect, verifyEmail);
router.patch('/deposit', protect, depositBalance);

// Password Management
router.post('/change-password', protect, changePassword);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/logout', protect, logoutUser);
router.post('/feedback', protect, submitFeedback);

module.exports = router;