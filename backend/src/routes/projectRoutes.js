const express = require('express');
const router = express.Router();
const { 
  createProject, 
  getAllProjects, 
  getSellerProjects, 
  updateProject,
  watchProject
} = require('../controllers/projectController');
const { protect } = require('../middlewares/authMiddleware');
const upload = require('../config/multer');

router.post('/upload', upload.single('file'), (req, res) => {
  res.status(200).json({ fileUrl: `/uploads/${req.file.filename}` });
});

router.get('/', getAllProjects);
router.post('/', protect, createProject);
router.get('/seller/:sellerId', protect, getSellerProjects);
router.post('/watch/:id', protect, watchProject);
router.patch('/:id', protect, updateProject); // Fixed Line 16

module.exports = router;