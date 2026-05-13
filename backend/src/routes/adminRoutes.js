const express = require('express');
const router = express.Router();
const { getReviewQueue, getProjectAudit, approveOrReject } = require('../controllers/adminController');
const { protect, authorize } = require('../middlewares/authMiddleware');

// All routes here require Admin role
router.use(protect, authorize('Admin'));

router.get('/queue', getReviewQueue);
router.get('/audit/:id', getProjectAudit);
router.post('/decision/:id', approveOrReject);

module.exports = router;