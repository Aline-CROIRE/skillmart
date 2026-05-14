const express = require('express');
const router = express.Router();
const { purchaseProject, getMyLibrary } = require('../controllers/marketController');
const { protect } = require('../middlewares/authMiddleware');

// Base path: /api/market
router.post('/purchase', protect, purchaseProject);
router.get('/my-library', protect, getMyLibrary); // This creates /api/market/my-library

module.exports = router;