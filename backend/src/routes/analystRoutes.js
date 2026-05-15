const express = require('express');
const router = express.Router();
const { getPendingQueue, claimProject, submitDecision } = require('../controllers/analystController');
const { protect, authorize, isConfirmedAnalyst } = require('../middlewares/authMiddleware');

// Security: Only Analysts and Admins
router.use(protect, authorize('Analyst', 'Admin'));

// Analysts must also be confirmed by Super Admin
router.get('/queue', isConfirmedAnalyst, getPendingQueue);
router.patch('/claim/:id', isConfirmedAnalyst, claimProject);
router.patch('/review/:id', isConfirmedAnalyst, submitDecision);

module.exports = router;