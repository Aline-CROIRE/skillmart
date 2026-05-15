const Project = require('../models/Project');
const User = require('../models/User');
const mongoose = require('mongoose');
const { sendSubmissionConfirmation } = require('../services/emailService');

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

    // Notify seller
    const user = await User.findById(sellerId);
    if (user && user.email) {
      sendSubmissionConfirmation(user.email, user.name, project.title).catch(err => 
        console.error('Submission email failed:', err)
      );
    }

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
    const projects = await Project.find({ status: 'approved' })
      .populate('sellerId', 'name')
      .sort({ createdAt: -1 });

    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.bookmarkProject = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const project = await Project.findById(id);
    if (!project) return res.status(404).json({ message: "Project not found" });

    const user = await User.findById(userId);
    
    const isBookmarked = user.bookmarkedProjects.includes(id);

    if (isBookmarked) {
      // Unbookmark
      user.bookmarkedProjects = user.bookmarkedProjects.filter(pId => pId.toString() !== id);
      project.watchers = project.watchers.filter(wId => wId.toString() !== userId.toString());
    } else {
      // Bookmark
      user.bookmarkedProjects.push(id);
      if (!project.watchers.includes(userId)) {
        project.watchers.push(userId);
      }
    }

    await user.save();
    await project.save();

    res.json({ message: isBookmarked ? "Removed from bookmarks" : "Bookmarked successfully", isBookmarked: !isBookmarked });
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

exports.requestAnalyticsAccess = async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ message: "Project not found" });

    // Check if already requested
    const existing = project.analyticsAccessRequests.find(r => r.userId.toString() === req.user._id.toString());
    if (existing) {
      return res.status(400).json({ message: "You already have a pending or granted request for this analytics document." });
    }

    project.analyticsAccessRequests.push({ userId: req.user._id, status: 'pending' });
    await project.save();

    res.json({ message: "Request sent. Waiting for Admin approval.", status: 'pending' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};