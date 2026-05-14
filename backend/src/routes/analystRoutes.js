const express = require('express');
const router = express.Router();
const { purchaseProject, getMyLibrary } = require('../controllers/marketController');
const { protect } = require('../middlewares/authMiddleware');

/**
 * @openapi
 * /api/market/purchase:
 *   post:
 *     summary: Buy a project using wallet balance
 *     tags: [Marketplace]
 */
router.post('/purchase', protect, purchaseProject);

/**
 * @openapi
 * /api/market/my-library:
 *   get:
 *     summary: Get all projects owned by the logged-in user
 *     tags: [Marketplace]
 */
router.get('/my-library', protect, getMyLibrary);

module.exports = router;