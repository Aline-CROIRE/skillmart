const Project = require('../models/Project');
const User = require('../models/User');

exports.getAllProjects = async (req, res) => {
  try {
    const userId = req.query.userId;
    let filter = { status: 'approved' };

    // If a user is logged in, hide projects they already own
    if (userId && userId !== 'null') {
      const user = await User.findById(userId);
      if (user) {
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

exports.createProject = async (req, res) => {
  try {
    const project = await Project.create({ ...req.body, status: 'pending' });
    res.status(201).json(project);
  } catch (error) { res.status(500).json({ message: error.message }); }
};

exports.getSellerProjects = async (req, res) => {
  try {
    const projects = await Project.find({ sellerId: req.params.sellerId });
    res.json(projects);
  } catch (error) { res.status(500).json({ message: error.message }); }
};