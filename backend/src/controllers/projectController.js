const Project = require('../models/Project');

// Create a new project (Status starts as 'pending' for Analysts)
exports.createProject = async (req, res, next) => {
  try {
    const { title, description, category, price, fileUrl, sellerId } = req.body;

    const project = await Project.create({
      title,
      description,
      category,
      price: Number(price) || 0,
      fileUrl,
      sellerId,
      status: 'pending' // Projects start here
    });

    res.status(201).json(project);
  } catch (error) {
    console.error("CREATE PROJECT ERROR:", error);
    res.status(500).json({ message: error.message });
  }
};

// Get only approved projects for the marketplace
exports.getAllProjects = async (req, res, next) => {
  try {
    const projects = await Project.find({ status: 'approved' })
      .populate('sellerId', 'name')
      .sort({ createdAt: -1 });
    res.json(projects);
  } catch (error) {
    next(error);
  }
};

// Get specific seller's projects (for "My Contributions" screen)
exports.getSellerProjects = async (req, res, next) => {
  try {
    const projects = await Project.find({ sellerId: req.params.sellerId })
      .sort({ createdAt: -1 });
    res.json(projects);
  } catch (error) {
    next(error);
  }
};