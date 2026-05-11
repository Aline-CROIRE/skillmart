const express = require('express');
const router = express.Router();
const { getSellerProjects, resubmitProject } = require('../controllers/sellerController');

/**
 * @openapi
 * /api/seller/projects/{sellerId}:
 *   get:
 *     summary: Get all projects by a seller
 *     tags: [Seller]
 */
router.get('/projects/:sellerId', getSellerProjects);

/**
 * @openapi
 * /api/seller/resubmit/{id}:
 *   post:
 *     summary: Resubmit a project for analysis
 *     tags: [Seller]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               category:
 *                 type: string
 *               fileUrl:
 *                 type: string
 */
router.post('/resubmit/:id', resubmitProject);

module.exports = router;