const express = require('express');
const router = express.Router();
const { purchaseProject } = require('../controllers/marketController');
const { protect } = require('../middlewares/authMiddleware');

/**
 * @openapi
 * /api/market/purchase:
 *   post:
 *     summary: Purchase a project
 *     tags: [Marketplace]
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               projectId: { type: string }
 *     responses:
 *       200:
 *         description: Purchase successful
 *       400:
 *         description: Insufficient funds or project not found
 */
router.post('/purchase', protect, purchaseProject);

module.exports = router;