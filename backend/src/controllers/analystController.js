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
const { createNotification } = require('../services/notificationService');

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

    if (!project) return res.status(404).json({ message: "Project not found" });

    // Notify Bookmarkers only on REJECTION (Final)
    // Approval notifications happen when Admin makes the final decision
    if (status === 'rejected' && project.watchers && project.watchers.length > 0) {
      for (const user of project.watchers) {
        if (user.email) sendNotificationEmail(user.email, project.title, 'rejected');
        await createNotification(
          user, 
          'Project Update', 
          `Project "${project.title}" did not meet the criteria for approval at this time.`,
          'project_update',
          project._id
        );
      }
      project.watchers = [];
      await project.save();
    }

    // Notify Owner on Analyst Progress
    if (project.sellerId) {
      if (status === 'pending_approval') {
        if (project.sellerId.email) sendNotificationEmail(project.sellerId.email, project.title, 'pending_approval');
        await createNotification(
          project.sellerId, 
          'Good News!', 
          `Your project "${project.title}" has passed expert review and is awaiting final Admin approval.`,
          'project_update',
          project._id
        );

        // NEW: Notify all Admins that a project is ready for sign-off
        const admins = await User.find({ role: 'Admin' });
        for (const adminUser of admins) {
          await createNotification(
            adminUser,
            'New Project for Approval',
            `Analyst has submitted "${project.title}" for final sign-off.`,
            'admin_broadcast',
            project._id
          );
        }
      } else if (status === 'needs_changes') {
        if (project.sellerId.email) sendNotificationEmail(project.sellerId.email, project.title, 'needs_changes');
        await createNotification(
          project.sellerId, 
          'Action Required!', 
          `An expert has requested a review for your project "${project.title}". Check feedback and resubmit.`,
          'project_update',
          project._id
        );
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