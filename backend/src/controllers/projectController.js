const Project = require('../models/Project');
const User = require('../models/User');
const mongoose = require('mongoose');
const { sendSubmissionConfirmation } = require('../services/emailService');
const { createNotification } = require('../services/notificationService');

exports.createProject = async (req, res) => {
  try {
    const { sellerId } = req.body;

    if (!mongoose.Types.ObjectId.isValid(sellerId)) {
      return res.status(400).json({ message: "Invalid user session." });
    }

    const existingProject = await Project.findOne({ sellerId, title: req.body.title });
    if (existingProject) {
      return res.status(400).json({ message: "You have already uploaded a project with this title." });
    }

    const project = await Project.create({
      ...req.body,
      status: 'pending'
    });

    // Notify seller
    const user = await User.findById(sellerId);
    if (user) {
      if (user.email) {
        sendSubmissionConfirmation(user.email, user.name, project.title).catch(err => 
          console.error('Submission email failed:', err)
        );
      }
      await createNotification(
        user,
        'Project Submitted',
        `Your project "${project.title}" has been successfully submitted and is now in the queue for expert review.`,
        'project_update',
        project._id
      );
    }

    res.status(201).json(project);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
exports.updateProject = async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    if (!project) return res.status(404).json({ message: "Project not found" });

    const newStatus = project.analystId ? 'resubmitted' : 'pending';

    const updatedProject = await Project.findByIdAndUpdate(
      req.params.id,
      { 
        ...req.body,
        status: newStatus, 
        reviewNote: "" 
      },
      { new: true }
    ).populate('analystId');

    if (!updatedProject) return res.status(404).json({ message: "Project not found" });

    // Notify Analyst if they are assigned
    if (updatedProject.analystId) {
      await createNotification(
        updatedProject.analystId,
        'Project Resubmitted',
        `The owner has resubmitted "${updatedProject.title}" with updates. Please verify the changes.`,
        'project_update',
        updatedProject._id
      );
    }

    res.json(updatedProject);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getAllProjects = async (req, res) => {
  try {
    const userId = req.user?._id?.toString();
    const isStaff = req.user?.role === 'Admin' || req.user?.role === 'Analyst';

    let query = { status: { $ne: 'rejected' } };
    if (userId) {
      if (isStaff) {
        query = {}; // Staff sees everything
      } else {
        query = {
          $or: [
            { status: { $ne: 'rejected' } },
            { sellerId: userId }
          ]
        };
      }
    }

    let projects = await Project.find(query)
      .populate('sellerId', 'name')
      .sort({ createdAt: -1 });

    // Status Masking Logic
    projects = projects.map(p => {
      const pObj = p.toObject();
      const isCreator = userId && pObj.sellerId?._id?.toString() === userId;
      
      // If not creator and not staff, mask status
      if (!isCreator && !isStaff) {
        if (pObj.status !== 'approved') {
          pObj.status = 'pending';
        }
      }
      return pObj;
    });

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

    const pObj = project.toObject();
    const userId = req.user?._id?.toString();
    const isStaff = req.user?.role === 'Admin' || req.user?.role === 'Analyst';
    const isCreator = userId && pObj.sellerId?._id?.toString() === userId;

    if (!isCreator && !isStaff && pObj.status !== 'approved') {
      pObj.status = 'pending';
    }

    res.json(pObj);
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

    // Notify user of request receipt
    await createNotification(
      req.user,
      'Analytics Request Received',
      `Your request for analytics access on "${project.title}" has been sent to the Admin for approval.`,
      'security',
      project._id
    );

    res.json({ message: "Request sent. Waiting for Admin approval.", status: 'pending' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};