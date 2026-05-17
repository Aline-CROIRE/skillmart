const Project = require('../models/Project');
const Analysis = require('../models/Analysis');
const User = require('../models/User');
const { sendNotificationEmail, sendAnalystCredentialsEmail, sendMail, getHtmlTemplate, getLogoUrl } = require('../services/emailService');
const { createNotification, sendPushNotification } = require('../services/notificationService');
const Notification = require('../models/Notification');

// Get all projects waiting for final Admin approval
exports.getReviewQueue = async (req, res, next) => {
  try {
    const queue = await Project.find({ status: 'pending_approval' }).populate('sellerId', 'name');
    res.json(queue);
  } catch (error) { next(error); }
};

// Get ALL projects in the system (Admin only)
exports.getAllProjects = async (req, res, next) => {
  try {
    const projects = await Project.find().populate('sellerId', 'name email');
    res.json(projects);
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
        
        const pushTitle = status === 'approved' ? 'Expert Review Complete!' : 'Project Update';
        const pushBody = status === 'approved' 
          ? `Analytics for "${project.title}" are now available.` 
          : `Project "${project.title}" was not approved at this time.`;
        
        await createNotification(user, pushTitle, pushBody, 'project_update', project._id);
      }
      project.watchers = [];
      await project.save();
    }

    // Notify Owner
    if (project.sellerId) {
      if (project.sellerId.email) sendNotificationEmail(project.sellerId.email, project.title, status);
      await createNotification(
        project.sellerId, 
        'Status Update', 
        `Your project "${project.title}" has been ${status}.`, 
        'project_update', 
        project._id
      );
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

    user.role = targetRole;
    await user.save();

    await createNotification(
      user, 
      'Role Updated', 
      `Your account has been ${action === 'promote' ? 'promoted to Analyst' : 'updated to User'}.`, 
      'security'
    );

    res.json({ message: `User ${email} successfully ${action}`, user: { email: user.email, role: user.role } });
  } catch (error) { next(error); }
};

// Get all analysts
exports.getAnalysts = async (req, res, next) => {
  try {
    const analysts = await User.find({ role: 'Analyst' })
      .select('name email phoneNumber isPaused pausedUntil isProfileConfirmed nationalIdUrl verificationSelfieUrl avatar emailVerified');
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
    console.log(`Attempting to send credentials to ${email}...`);
    await sendAnalystCredentialsEmail(email, name, password);

    console.log(`Analyst ${email} created successfully.`);
    res.status(201).json({ message: "Analyst account created and credentials emailed", analyst: { name, email } });
  } catch (error) { 
    console.error('Analyst Creation Error:', error);
    next(error); 
  }
};

// Confirm Analyst Profile
exports.confirmAnalystProfile = async (req, res, next) => {
  try {
    const { userId } = req.body;
    const user = await User.findById(userId);
    if (!user || user.role !== 'Analyst') return res.status(404).json({ message: "Analyst not found" });

    // REQUIREMENT: Check for phone number, ID, and Selfie
    if (!user.phoneNumber || !user.nationalIdUrl || !user.verificationSelfieUrl) {
      return res.status(400).json({ 
        message: "Compliance Incomplete", 
        detail: "Analyst must have Phone Number, National ID, and Verification Selfie uploaded." 
      });
    }

    user.isProfileConfirmed = true;
    await user.save();

    await createNotification(user, 'Profile Confirmed', 'Your analyst profile has been verified. You can now start evaluating projects!', 'security');

    res.json({ message: "Analyst profile confirmed successfully", isProfileConfirmed: true });
  } catch (error) { next(error); }
};

// Unconfirm Analyst Profile
exports.unconfirmAnalystProfile = async (req, res, next) => {
  try {
    const { userId } = req.body;
    const user = await User.findById(userId);
    if (!user || user.role !== 'Analyst') return res.status(404).json({ message: "Analyst not found" });

    user.isProfileConfirmed = false;
    await user.save();

    await createNotification(user, 'Profile Access Revoked', 'Your profile confirmation has been reversed by an admin. Please contact support.', 'security');

    res.json({ message: "Analyst profile unconfirmed successfully", isProfileConfirmed: false });
  } catch (error) { next(error); }
};

// Update Analyst Info (Admin only)
exports.updateAnalyst = async (req, res, next) => {
  try {
    const { userId, name, email, phoneNumber } = req.body;
    const user = await User.findById(userId);
    if (!user || user.role !== 'Analyst') return res.status(404).json({ message: "Analyst not found" });

    if (name) user.name = name;
    if (phoneNumber) user.phoneNumber = phoneNumber;
    
    if (email && email !== user.email) {
      const exists = await User.findOne({ email });
      if (exists) return res.status(400).json({ message: "Email already in use" });
      user.email = email;
      user.emailVerified = false; // Reset verification if email changes
    }

    await user.save();
    res.json({ message: "Analyst updated successfully", user });
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

// 7. Get all projects with pending analytics document requests
exports.getAnalyticsRequests = async (req, res, next) => {
  try {
    const projects = await Project.find({ 
      'analyticsAccessRequests.status': 'pending' 
    }).populate('analyticsAccessRequests.userId', 'name email');
    
    // Flatten for easier UI consumption
    const flattened = [];
    projects.forEach(p => {
      p.analyticsAccessRequests.forEach(reqObj => {
        if (reqObj.status === 'pending') {
          flattened.push({
            requestId: reqObj._id,
            projectId: p._id,
            projectTitle: p.title,
            userId: reqObj.userId._id,
            userName: reqObj.userId.name,
            userEmail: reqObj.userId.email,
            requestedAt: reqObj.requestedAt
          });
        }
      });
    });
    
    res.json(flattened);
  } catch (error) { next(error); }
};

// 9. Get all users in the system
exports.getUsers = async (req, res, next) => {
  try {
    const users = await User.find({}, 'name email role fcmToken');
    res.json(users);
  } catch (error) { next(error); }
};

// 10. Send a manual notification to a specific user
exports.sendNotificationToUser = async (req, res, next) => {
  try {
    const { userId, title, body, type } = req.body;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    await createNotification(
      user,
      title || "System Alert",
      body || "This is a manual notification from Admin.",
      type || "admin_broadcast"
    );

    res.json({ message: "Notification sent successfully" });
  } catch (error) { next(error); }
};

// 11. Broadcast Notification to roles
exports.broadcastNotification = async (req, res, next) => {
  try {
    const { role, title, body } = req.body; // role: 'Admin', 'Analyst', 'User', or 'All'
    
    let query = {};
    if (role && role !== 'All') {
      query.role = role;
    }

    const users = await User.find(query);
    
    for (const user of users) {
      await createNotification(
        user,
        title || "Broadcast Alert",
        body || "Important announcement from SkillMart Admin.",
        'admin_broadcast'
      );
    }

    res.json({ message: `Broadcast sent to ${users.length} users.` });
  } catch (error) { next(error); }
};

// 12. Send Newsletter (Respects subscriptions & preferences)
exports.sendNewsletter = async (req, res, next) => {
  try {
    const { title, body } = req.body;
    console.log(`📣 Dispatching newsletter: "${title}"`);
    
    // Find all users subscribed to newsletter
    const users = await User.find({ isSubscribedToNewsletter: true });
    console.log(`👥 Found ${users.length} subscribers.`);

    const logoUrl = await getLogoUrl();
    
    let successCount = 0;
    for (const user of users) {
      try {
        // 1. Tray (Undebatable - always saved to DB)
        await Notification.create({
          userId: user._id,
          title,
          message: body,
          type: 'newsletter',
        });

        // 2. Push (If preferred)
        if (user.newsletterPreferences.push && user.fcmToken) {
          await sendPushNotification(user.fcmToken, title, body, {}, 'newsletter');
        }

        // 3. Email (If preferred)
        if (user.newsletterPreferences.email && user.email) {
          const html = getHtmlTemplate(title, `<p>${body}</p>`, logoUrl);
          await sendMail(user.email, title, body, html);
        }
        successCount++;
      } catch (err) {
        console.error(`❌ Failed to send newsletter to ${user.email}:`, err.message);
      }
    }

    res.json({ message: `Newsletter dispatched! Successfully sent to ${successCount} out of ${users.length} subscribers.` });
  } catch (error) { 
    console.error('🔥 Fatal error in sendNewsletter:', error);
    next(error); 
  }
};

// 13. Get all dispatched notifications history
exports.getNotificationsHistory = async (req, res, next) => {
  try {
    const notifications = await Notification.find()
      .populate('userId', 'name email role')
      .sort({ createdAt: -1 });
    res.json(notifications);
  } catch (error) { next(error); }
};

// 8. Update Analytics Access Status (Grant/Deny)
exports.updateAnalyticsRequestStatus = async (req, res, next) => {
  try {
    const { projectId, requestId, status } = req.body; // status: 'granted' or 'denied'
    
    const project = await Project.findById(projectId);
    if (!project) return res.status(404).json({ message: "Project not found" });

    const request = project.analyticsAccessRequests.id(requestId);
    if (!request) return res.status(404).json({ message: "Request not found" });

    request.status = status;
    await project.save();

    // Notify User
    const user = await User.findById(request.userId);
    if (user) {
      const title = status === 'granted' ? 'Analytics Access Granted!' : 'Analytics Request Update';
      const body = status === 'granted' 
        ? `You can now view the premium analytics for "${project.title}".`
        : `Your request for analytics on "${project.title}" was not approved.`;
      await createNotification(user, title, body, 'project_update', project._id);
    }

    res.json({ message: `Access request ${status} successfully.`, status });
  } catch (error) { next(error); }
};