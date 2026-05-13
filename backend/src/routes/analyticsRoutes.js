const express = require('express');
const router = express.Router();
const { getGlobalTrends } = require('../controllers/analyticsController');
const { protect, authorize } = require('../middlewares/authMiddleware');

/**
 * @openapi
 * /api/analytics/trends:
 *   get:
 *     summary: Get platform trends (Analyst Only)
 *     tags: [Analytics]
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200:
 *         description: Platform-wide performance data
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 categoryTrends: { type: array }
 *                 totalRevenue: { type: number }
 */
// Only 'Analyst' and 'Admin' roles can see global platform trends
router.get('/trends', protect, authorize('Analyst', 'Admin'), getGlobalTrends);

module.exports = router;