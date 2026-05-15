const Project = require('../models/Project');
const Analysis = require('../models/Analysis');
const { sendNotificationEmail } = require('../services/emailService');
const { sendPushNotification } = require('../services/notificationService');

// Get all projects waiting for review
exports.getReviewQueue = async (req, res, next) => {
  try {
    const queue = await Project.find({ status: 'pending' });
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