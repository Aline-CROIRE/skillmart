const express = require('express');
const router = express.Router();
const { getPendingQueue, claimProject, submitDecision } = require('../controllers/analystController');
const { protect, authorize } = require('../middlewares/authMiddleware');

// Security: Only Analysts and Admins
router.use(protect, authorize('Analyst', 'Admin'));

router.get('/queue', getPendingQueue);
router.patch('/claim/:id', claimProject);
router.patch('/review/:id', submitDecision); // Line 8: Now correctly finds 'submitDecision'

module.exports = router;