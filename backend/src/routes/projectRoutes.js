const express = require('express');
const router = express.Router();
const { createProject, getAllProjects, getSellerProjects } = require('../controllers/projectController');
const { protect } = require('../middlewares/authMiddleware');
const upload = require('../config/multer');

/**
 * @openapi
 * /api/projects/upload:
 *   post:
 *     summary: Upload physical file
 *     tags: [Projects]
 */
router.post('/upload', upload.single('file'), (req, res) => {
  res.status(200).json({ fileUrl: `/uploads/${req.file.filename}` });
});

/**
 * @openapi
 * /api/projects:
 *   post:
 *     summary: Create project metadata
 *     tags: [Projects]
 */
router.post('/', protect, createProject);

/**
 * @openapi
 * /api/projects:
 *   get:
 *     summary: Get all approved marketplace projects
 *     tags: [Projects]
 */
router.get('/', getAllProjects);

/**
 * @openapi
 * /api/projects/seller/{sellerId}:
 *   get:
 *     summary: Get all projects by a specific seller
 *     tags: [Projects]
 */
router.get('/seller/:sellerId', protect, getSellerProjects);

module.exports = router;