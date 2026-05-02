const express = require('express');
const router = express.Router();
const upload = require('../config/multer');
const { uploadFile, createProject } = require('../controllers/projectController');

/**
 * @openapi
 * /api/projects/upload:
 *   post:
 *     summary: Upload a project file
 *     tags: [Projects]
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: File uploaded successfully
 */
router.post('/upload', upload.single('file'), uploadFile);

/**
 * @openapi
 * /api/projects:
 *   post:
 *     summary: Create a new project submission
 *     tags: [Projects]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - description
 *               - category
 *               - sellerId
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               category:
 *                 type: string
 *                 enum: [Web, Mobile, AI, Design, Other]
 *               fileUrl:
 *                 type: string
 *               sellerId:
 *                 type: string
 *     responses:
 *       201:
 *         description: Project created
 */
router.post('/', createProject);

module.exports = router;