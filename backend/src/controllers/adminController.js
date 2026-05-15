const Project = require('../models/Project');
const Analysis = require('../models/Analysis');
const User = require('../models/User');
const { sendNotificationEmail, sendAnalystCredentialsEmail } = require('../services/emailService');
const { sendPushNotification } = require('../services/notificationService');

// Get all projects waiting for final Admin approval
exports.getReviewQueue = async (req, res, next) => {
  try {
    const queue = await Project.find({ status: 'pending_approval' }).populate('sellerId', 'name');
    res.json(queue);
  } catch (error) { next(error); }
};

// Get details + AI Audit for a specific project
exports.getProjectAudit = async (req, res, next) => {
  try {
    const project = await Project.findById(req.params.id);
    const audit = await Analysis.findOne({ projectId: req.params.id });
    res.json({ project, audit });
  } catch (error) { next(error); }
};

// Final decision by Admin
exports.approveOrReject = async (req, res, next) => {
  try {
    const { status } = req.body; // 'approved' or 'rejected'
    const project = await Project.findByIdAndUpdate(
      req.params.id, 
      { status }, 
      { new: true }
    ).populate('watchers', 'email fcmToken').populate('sellerId', 'email fcmToken');

    if (!project) return res.status(404).json({ message: "Project not found" });

    // Notify Bookmarkers
    if (project.watchers && project.watchers.length > 0) {
      for (const user of project.watchers) {
        if (user.email) sendNotificationEmail(user.email, project.title, status);
        if (user.fcmToken) {
          const pushTitle = status === 'approved' ? 'Expert Review Complete!' : 'Project Update';
          const pushBody = status === 'approved' 
            ? `Analytics for "${project.title}" are now available.` 
            : `Project "${project.title}" was not approved at this time.`;
          sendPushNotification(user.fcmToken, pushTitle, pushBody);
        }
      }
      project.watchers = [];
      await project.save();
    }

    // Notify Owner
    if (project.sellerId) {
      if (project.sellerId.email) sendNotificationEmail(project.sellerId.email, project.title, status);
      if (project.sellerId.fcmToken) {
        sendPushNotification(project.sellerId.fcmToken, 'Status Update', `Your project "${project.title}" has been ${status}.`);
      }
    }

    res.json({ message: `Project ${status} successfully`, project });
  } catch (error) { next(error); }
};

// Promote or Demote an Analyst
exports.manageAnalyst = async (req, res, next) => {
  try {
    const { email, action } = req.body; // action: 'promote' or 'demote'
    const targetRole = action === 'promote' ? 'Analyst' : 'User';

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    if (user.role === 'Admin') {
      return res.status(403).json({ message: "Cannot change role of an Admin" });
    }

    user.role = targetRole;
    await user.save();

    res.json({ 
      message: `User ${email} successfully ${action === 'promote' ? 'promoted to Analyst' : 'demoted to User'}`,
      user: { email: user.email, role: user.role }
    });
  } catch (error) { next(error); }
};

// Get all analysts
exports.getAnalysts = async (req, res, next) => {
  try {
    const analysts = await User.find({ role: 'Analyst' })
      .select('name email isPaused pausedUntil isProfileConfirmed nationalIdUrl avatar emailVerified');
    res.json(analysts);
  } catch (error) { next(error); }
};

// Create a new Analyst account
exports.createAnalyst = async (req, res, next) => {
  try {
    const { name, email, password } = req.body;
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: "User already exists" });

    const analyst = await User.create({
      name,
      email,
      password, // Password hashing is handled by User model pre-save middleware
      role: 'Analyst',
      emailVerified: false // They must verify themselves
    });

    // Send credentials via email
    await sendAnalystCredentialsEmail(email, name, password);

    res.status(201).json({ message: "Analyst account created and credentials emailed", analyst: { name, email } });
  } catch (error) { next(error); }
};

// Confirm Analyst Profile
exports.confirmAnalystProfile = async (req, res, next) => {
  try {
    const { userId } = req.body;
    const user = await User.findById(userId);
    if (!user || user.role !== 'Analyst') return res.status(404).json({ message: "Analyst not found" });

    user.isProfileConfirmed = true;
    await user.save();

    res.json({ message: "Analyst profile confirmed successfully", isProfileConfirmed: true });
  } catch (error) { next(error); }
};

// Toggle Analyst Pause
exports.togglePauseAnalyst = async (req, res, next) => {
  try {
    const { userId, days } = req.body; // days: null means indefinite, >0 means timed
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "Analyst not found" });

    if (user.isPaused) {
      // Unpause
      user.isPaused = false;
      user.pausedUntil = null;
    } else {
      // Pause
      user.isPaused = true;
      if (days && days > 0) {
        const date = new Date();
        date.setDate(date.getDate() + days);
        user.pausedUntil = date;
      } else {
        user.pausedUntil = null; // Indefinite
      }
    }

    await user.save();
    res.json({ 
      message: user.isPaused ? "Analyst paused" : "Analyst unpaused", 
      isPaused: user.isPaused,
      pausedUntil: user.pausedUntil 
    });
  } catch (error) { next(error); }
};