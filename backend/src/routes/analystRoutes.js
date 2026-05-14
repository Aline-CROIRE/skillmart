const express = require('express');
const router = express.Router();
const { getPendingQueue, claimProject, submitDecision } = require('../controllers/analystController');
const { protect, authorize } = require('../middlewares/authMiddleware');

// Standardize: Only Analysts and Admins can access this
router.get('/queue', protect, authorize('Analyst', 'Admin'), getPendingQueue);
router.patch('/claim/:id', protect, authorize('Analyst', 'Admin'), claimProject);
router.patch('/review/:id', protect, authorize('Analyst', 'Admin'), submitDecision);

module.exports = router;