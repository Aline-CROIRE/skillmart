const Project = require('../models/Project');

// 1. Get available projects (Waiting for an expert)
exports.getPendingQueue = async (req, res) => {
  try {
    const projects = await Project.find({ 
      status: 'pending'
    }).populate('sellerId', 'name');
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 2. Get my active assignments (Projects I am working on)
exports.getMyAssignments = async (req, res) => {
  try {
    const projects = await Project.find({ 
      analystId: req.user._id,
      status: 'under_review'
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
    let { status, reviewNote, price } = req.body;
    
    // WORKFLOW: Analyst "approval" sends it to Admin for final sign-off
    if (status === 'approved') {
      status = 'pending_approval';
    }

    const updateData = { status, reviewNote };
    if (price) updateData.price = Number(price);
    
    // Handle Analytics Document Upload
    if (req.file) {
      updateData.analyticsFileUrl = req.file.path;
    }

    const project = await Project.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('watchers', 'email fcmToken').populate('sellerId', 'email fcmToken');

    // Notify Bookmarkers only on REJECTION (Final)
    // Approval notifications happen when Admin makes the final decision
    if (status === 'rejected' && project.watchers && project.watchers.length > 0) {
      for (const user of project.watchers) {
        if (user.email) sendNotificationEmail(user.email, project.title, 'rejected');
        if (user.fcmToken) {
          sendPushNotification(
            user.fcmToken, 
            'Project Update', 
            `Project "${project.title}" did not meet the criteria for approval at this time.`
          );
        }
      }
      project.watchers = [];
      await project.save();
    }

    // Notify Owner on Analyst Progress
    if (project.sellerId) {
      const ownerEmail = project.sellerId.email;
      const ownerToken = project.sellerId.fcmToken;

      if (status === 'pending_approval') {
        if (ownerEmail) sendNotificationEmail(ownerEmail, project.title, 'pending_approval');
        if (ownerToken) sendPushNotification(ownerToken, 'Good News!', `Your project "${project.title}" has passed expert review and is awaiting final Admin approval.`);
      } else if (status === 'needs_changes') {
        if (ownerEmail) sendNotificationEmail(ownerEmail, project.title, 'needs_changes');
        if (ownerToken) sendPushNotification(ownerToken, 'Action Required!', `An expert has requested a review for your project "${project.title}". Check feedback and resubmit.`);
      }
    }

    res.json({ message: "Evaluation recorded. Awaiting admin final sign-off.", project });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 4. Get Analyst's history (projects they have reviewed)
exports.getAnalystHistory = async (req, res) => {
  try {
    const projects = await Project.find({ 
      analystId: req.user._id,
      status: { $nin: ['pending', 'under_review'] }
    }).sort({ updatedAt: -1 });
    res.json(projects);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};