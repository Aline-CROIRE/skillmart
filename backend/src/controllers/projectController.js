const Project = require('../models/Project');
const User = require('../models/User');
const mongoose = require('mongoose');

// 1. CREATE NEW
exports.createProject = async (req, res) => {
  try {
    const project = await Project.create({ ...req.body, status: 'pending' });
    res.status(201).json(project);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 2. UPDATE EXISTING (RE-SUBMISSION) - This fixes the crash
exports.updateProject = async (req, res) => {
  try {
    const { title, description, category, price, fileUrl } = req.body;
    const project = await Project.findByIdAndUpdate(
      req.params.id,
      { 
        title, description, category, price: Number(price), fileUrl, 
        status: 'pending', 
        reviewNote: "" 
      },
      { new: true }
    );
    res.json(project);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 3. MARKETPLACE VIEW (With Ownership Filtering)
exports.getAllProjects = async (req, res) => {
  try {
    const userId = req.query.userId;
    let filter = { status: 'approved' };

    if (userId && userId !== 'null' && mongoose.Types.ObjectId.isValid(userId)) {
      const user = await User.findById(userId);
      if (user) {
        // Hide projects the user has already bought
        filter._id = { $nin: user.purchasedProjects };
      }
    }

    const projects = await Project.find(filter)
      .populate('sellerId', 'name')
      .sort({ createdAt: -1 });
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 4. SELLER DASHBOARD
exports.getSellerProjects = async (req, res) => {
  try {
    const projects = await Project.find({ sellerId: req.params.sellerId })
      .sort({ createdAt: -1 });
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};