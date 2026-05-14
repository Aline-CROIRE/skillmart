const Project = require('../models/Project');
const mongoose = require('mongoose');

// 1. CREATE PROJECT (Seller Upload)
exports.createProject = async (req, res, next) => {
  try {
    const { title, description, category, price, fileUrl, sellerId } = req.body;

    // Log incoming data for debugging in Render
    console.log("📥 New Submission Received:", { title, category, price, sellerId });

    // Validation: Ensure sellerId is a real MongoDB ID
    if (!mongoose.Types.ObjectId.isValid(sellerId)) {
      console.error("❌ Invalid Seller ID format:", sellerId);
      return res.status(400).json({ 
        message: "Your session has expired. Please logout and login again." 
      });
    }

    // Save to Database
    const project = await Project.create({
      title,
      description,
      category,
      price: Number(price) || 0, // Ensure it is a number
      fileUrl,
      sellerId,
      status: 'pending' // Human Analysts look for 'pending' projects
    });

    console.log("✅ Project Created in DB:", project._id);
    res.status(201).json(project);

  } catch (error) {
    console.error("❌ CREATE PROJECT CRASH:", error.message);
    res.status(500).json({ message: "Server Error", error: error.message });
  }
};

// 2. MARKETPLACE VIEW (Get Approved Projects)
exports.getAllProjects = async (req, res, next) => {
  try {
    // Only show 'approved' projects in the marketplace
    const projects = await Project.find({ status: 'approved' })
      .populate('sellerId', 'name')
      .sort({ createdAt: -1 });
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 3. SELLER DASHBOARD (Get specific user's work)
exports.getSellerProjects = async (req, res, next) => {
  try {
    const projects = await Project.find({ sellerId: req.params.sellerId })
      .sort({ createdAt: -1 });
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};