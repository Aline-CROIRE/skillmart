const Project = require('../models/Project');
const User = require('../models/User');
const mongoose = require('mongoose');

exports.createProject = async (req, res) => {
  try {
    const { sellerId } = req.body;

    if (!mongoose.Types.ObjectId.isValid(sellerId)) {
      return res.status(400).json({ message: "Invalid user session." });
    }

    const project = await Project.create({
      ...req.body,
      status: 'pending'
    });

    res.status(201).json(project);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateProject = async (req, res) => {
  try {
    const project = await Project.findByIdAndUpdate(
      req.params.id,
      { 
        ...req.body,
        status: 'pending', 
        reviewNote: "" 
      },
      { new: true }
    );

    if (!project) return res.status(404).json({ message: "Project not found" });
    res.json(project);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getAllProjects = async (req, res) => {
  try {
    const userId = req.query.userId;
    let filter = { status: 'approved' };

    if (userId && userId !== 'null' && mongoose.Types.ObjectId.isValid(userId)) {
      const user = await User.findById(userId);
      if (user) {
        filter = {
          $and: [
            { status: 'approved' },
            { sellerId: { $ne: new mongoose.Types.ObjectId(userId) } },
            { _id: { $nin: user.purchasedProjects } }
          ]
        };
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

exports.getSellerProjects = async (req, res) => {
  try {
    const { sellerId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(sellerId)) {
      return res.status(400).json({ message: "Invalid Seller ID" });
    }

    const projects = await Project.find({ sellerId }).sort({ createdAt: -1 });
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getProjectById = async (req, res) => {
  try {
    const project = await Project.findById(req.params.id).populate('sellerId', 'name');
    if (!project) return res.status(404).json({ message: "Project not found" });
    res.json(project);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};