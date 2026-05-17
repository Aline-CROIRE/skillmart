const express = require('express');
const router = express.Router();
const { 
  getReviewQueue, 
  getAllProjects,
  getProjectAudit, 
  approveOrReject, 
  manageAnalyst,
  getAnalysts,
  createAnalyst,
  togglePauseAnalyst,
  confirmAnalystProfile,
  unconfirmAnalystProfile,
  updateAnalyst,
  getAnalyticsRequests,
  updateAnalyticsRequestStatus,
  getUsers,
  sendNotificationToUser,
  broadcastNotification,
  sendNewsletter,
  getNotificationsHistory
} = require('../controllers/adminController');
const { protect, authorize } = require('../middlewares/authMiddleware');

// All routes here require Admin role
router.use(protect, authorize('Admin'));

/**
 * @swagger
 * /api/admin/broadcast:
 *   post:
 *     summary: Send a broadcast notification to a specific role or everyone
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [title, body]
 *             properties:
 *               role: { type: string, enum: [Admin, Analyst, User, All], default: All }
 *               title: { type: string }
 *               body: { type: string }
 *     responses:
 *       200:
 *         description: Broadcast sent successfully
 */
router.post('/broadcast', broadcastNotification);

/**
 * @swagger
 * /api/admin/newsletter:
 *   post:
 *     summary: Send a newsletter to subscribed users (respects preferences)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [title, body]
 *             properties:
 *               title: { type: string }
 *               body: { type: string }
 *     responses:
 *       200:
 *         description: Newsletter sent successfully
 */
router.post('/newsletter', sendNewsletter);

/**
 * @swagger
 * tags:
 *   name: Admin
 *   description: Administrative management for projects and analysts
 */

/**
 * @swagger
 * /api/admin/projects:
 *   get:
 *     summary: Get all projects in the system
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of all projects
 */
router.get('/projects', getAllProjects);

/**
 * @swagger
 * /api/admin/queue:
 *   get:
 *     summary: Get projects waiting for approval
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of pending projects
 */
router.get('/queue', getReviewQueue);

/**
 * @swagger
 * /api/admin/audit/{id}:
 *   get:
 *     summary: Get detailed project audit/analysis
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Project and audit details
 */
router.get('/audit/:id', getProjectAudit);

/**
 * @swagger
 * /api/admin/decision/{id}:
 *   post:
 *     summary: Approve, Reject, or Reverse a project status
 *     description: |
 *       Set status to:
 *       - 'approved': Project goes public, notifications sent to owner and watchers.
 *       - 'rejected': Project is hidden, notifications sent.
 *       - 'pending_approval': Reverses approval/rejection (back to admin queue).
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [approved, rejected, pending_approval]
 *     responses:
 *       200:
 *         description: Decision processed successfully
 */
router.post('/decision/:id', approveOrReject);
router.post('/manage-analyst', manageAnalyst);
router.get('/analysts', getAnalysts);
router.post('/create-analyst', createAnalyst);
router.post('/pause-analyst', togglePauseAnalyst);
router.post('/confirm-profile', confirmAnalystProfile);
router.post('/unconfirm-profile', unconfirmAnalystProfile);
router.patch('/update-analyst', updateAnalyst);
router.get('/analytics-requests', getAnalyticsRequests);
router.post('/analytics-decision', updateAnalyticsRequestStatus);

/**
 * @swagger
 * /api/admin/users:
 *   get:
 *     summary: Get all users in the system (Admin only)
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of users with FCM tokens
 */
router.get('/users', getUsers);

/**
 * @swagger
 * /api/admin/send-notification:
 *   post:
 *     summary: Send a manual notification to a specific user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [userId, title, body]
 *             properties:
 *               userId: { type: string }
 *               title: { type: string }
 *               body: { type: string }
 *               type: { type: string, enum: [project_update, security, wallet, admin_broadcast] }
 *     responses:
 *       200:
 *         description: Notification sent successfully
 */
router.post('/send-notification', sendNotificationToUser);
router.post('/newsletter', sendNewsletter);
router.get('/notifications-history', getNotificationsHistory);

module.exports = router;