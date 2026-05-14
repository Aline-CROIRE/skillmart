const Project = require('../models/Project');
const { sendApprovalEmail } = require('../services/emailService');

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

// 3. Analyst submits final evaluation (Matches line 8 in routes)
exports.submitDecision = async (req, res) => {
  try {
    const { status, reviewNote, price } = req.body;
    const updateData = { status, reviewNote };
    if (price) updateData.price = Number(price);

    const project = await Project.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('watchers', 'email');

    if (status === 'approved' && project.watchers && project.watchers.length > 0) {
      for (const user of project.watchers) {
        if (user.email) {
          sendApprovalEmail(user.email, project.title);
        }
      }
      // Clear watchers after notifying
      project.watchers = [];
      await project.save();
    }

    res.json({ message: "Evaluation recorded", project });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};