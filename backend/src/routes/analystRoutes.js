const express = require('express');
const router = express.Router();
const { getPendingQueue, claimProject, submitDecision, getAnalystHistory, getMyAssignments } = require('../controllers/analystController');
const { protect, authorize, isConfirmedAnalyst } = require('../middlewares/authMiddleware');
const cloudinaryUpload = require('../config/cloudinary');

// Security: Only Analysts and Admins
router.use(protect, authorize('Analyst', 'Admin'));

// Analysts must also be confirmed by Super Admin
router.get('/queue', isConfirmedAnalyst, getPendingQueue);
router.get('/assignments', isConfirmedAnalyst, getMyAssignments);
router.get('/history', isConfirmedAnalyst, getAnalystHistory);
router.patch('/claim/:id', isConfirmedAnalyst, claimProject);
router.patch('/review/:id', isConfirmedAnalyst, cloudinaryUpload.single('analyticsFile'), submitDecision);

module.exports = router;