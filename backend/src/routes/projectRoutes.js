const express = require('express');
const router = express.Router();
const { createProject, getAllProjects, getSellerProjects, updateProject } = require('../controllers/projectController');
const { protect } = require('../middlewares/authMiddleware');
const upload = require('../config/multer');

router.post('/upload', upload.single('file'), (req, res) => {
  res.status(200).json({ fileUrl: `/uploads/${req.file.filename}` });
});

router.post('/', protect, createProject);
router.get('/', getAllProjects);
router.get('/seller/:sellerId', protect, getSellerProjects);

// NEW: Update route for resubmissions
router.patch('/:id', protect, updateProject); 

module.exports = router;