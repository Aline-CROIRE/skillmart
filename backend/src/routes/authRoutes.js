const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getProfile, depositBalance } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/profile', protect, getProfile); // RESTORED
router.patch('/deposit', protect, depositBalance);

module.exports = router;