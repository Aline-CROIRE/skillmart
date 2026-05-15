const Project = require('../models/Project');

// 1. Get all projects waiting for an expert
exports.getPendingQueue = async (req, res) => {
  try {
    const projects = await Project.find({ 
      status: { $in: ['pending', 'under_review', 'needs_changes'] } 
    }).populate('sellerId', 'name');
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 2. Analyst claims a project
exports.claimProject = async (req, res) => {
  try {
    const project = await Project.findByIdAndUpdate(
      req.params.id,
      { status: 'under_review', analystId: req.user._id },
      { new: true }
    );
    res.json(project);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const { sendNotificationEmail } = require('../services/emailService');
const { sendPushNotification } = require('../services/notificationService');

// ... (previous functions unchanged)

// 3. Analyst submits final evaluation
exports.submitDecision = async (req, res) => {
  try {
    const { status, reviewNote, price } = req.body;
    const updateData = { status, reviewNote };
    if (price) updateData.price = Number(price);

    const project = await Project.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('watchers', 'email fcmToken').populate('sellerId', 'email fcmToken');

    // Notify Bookmarkers
    if (project.watchers && project.watchers.length > 0) {
      for (const user of project.watchers) {
        if (user.email) {
          sendNotificationEmail(user.email, project.title, status);
        }
        if (user.fcmToken) {
          let pushTitle = ''; let pushBody = '';
          if (status === 'approved') {
            pushTitle = 'Expert Review Complete!';
            pushBody = `Analytics for "${project.title}" are now available in your feed.`;
          } else if (status === 'rejected') {
            pushTitle = 'Project Update';
            pushBody = `Project "${project.title}" did not meet the criteria for approval at this time.`;
          }
          if (pushTitle) sendPushNotification(user.fcmToken, pushTitle, pushBody);
        }
      }
      // Clear watchers after notifying only if it's a final state (approved/rejected)
      if (status === 'approved' || status === 'rejected') {
        project.watchers = [];
        await project.save();
      }
    }

    // SPECIFIC: Notify Owner if review is requested
    if (status === 'needs_changes' && project.sellerId) {
      if (project.sellerId.email) {
        sendNotificationEmail(project.sellerId.email, project.title, 'needs_changes');
      }
      if (project.sellerId.fcmToken) {
        sendPushNotification(
          project.sellerId.fcmToken, 
          'Action Required!', 
          `An expert has requested a review for your project "${project.title}". Check feedback and resubmit.`
        );
      }
    }

    res.json({ message: "Evaluation recorded", project });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};