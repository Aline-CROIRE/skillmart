const express = require('express');
const router = express.Router();
const { registerUser, loginUser, depositBalance } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.patch('/deposit', protect, depositBalance); // NEW

module.exports = router;