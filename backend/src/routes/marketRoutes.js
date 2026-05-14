const express = require('express');
const router = express.Router();
const { purchaseProject, getMyLibrary, getTransactionHistory } = require('../controllers/marketController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/purchase', protect, purchaseProject);
router.get('/my-library', protect, getMyLibrary);
router.get('/history', protect, getTransactionHistory);

module.exports = router;