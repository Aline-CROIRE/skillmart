const express = require('express');
const router = express.Router();
const { 
  createProject, 
  getAllProjects, 
  getSellerProjects, 
  updateProject,
  bookmarkProject
} = require('../controllers/projectController');
const { protect } = require('../middlewares/authMiddleware');
const cloudinaryUpload = require('../config/cloudinary');

router.post('/upload', cloudinaryUpload.single('file'), (req, res) => {
  res.status(200).json({ fileUrl: req.file.path });
});

router.get('/', getAllProjects);
router.post('/', protect, createProject);
router.get('/seller/:sellerId', protect, getSellerProjects);
router.post('/bookmark/:id', protect, bookmarkProject);
router.patch('/:id', protect, updateProject); // Fixed Line 16

module.exports = router;