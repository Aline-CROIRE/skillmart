const express = require('express');
const router = express.Router();
const { 
  getReviewQueue, 
  getProjectAudit, 
  approveOrReject, 
  manageAnalyst,
  getAnalysts,
  createAnalyst,
  togglePauseAnalyst,
  confirmAnalystProfile,
  getAnalyticsRequests,
  updateAnalyticsRequestStatus
} = require('../controllers/adminController');
const { protect, authorize } = require('../middlewares/authMiddleware');

// All routes here require Admin role
router.use(protect, authorize('Admin'));

router.get('/queue', getReviewQueue);
router.get('/audit/:id', getProjectAudit);
router.post('/decision/:id', approveOrReject);
router.post('/manage-analyst', manageAnalyst);
router.get('/analysts', getAnalysts);
router.post('/create-analyst', createAnalyst);
router.post('/pause-analyst', togglePauseAnalyst);
router.post('/confirm-profile', confirmAnalystProfile);
router.get('/analytics-requests', getAnalyticsRequests);
router.post('/analytics-decision', updateAnalyticsRequestStatus);

module.exports = router;