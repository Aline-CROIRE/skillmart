const Project = require('../models/Project');

// Get queue of all pending projects (For any analyst to see)
exports.getPendingQueue = async (req, res) => {
  const projects = await Project.find({ status: 'pending' }).populate('sellerId', 'name');
  res.json(projects);
};

// Analyst "claims" the project (Changes status to under_review)
exports.claimProject = async (req, res) => {
  const project = await Project.findByIdAndUpdate(
    req.params.id,
    { status: 'under_review', analystId: req.user._id },
    { new: true }
  );
  res.json(project);
};

// Analyst submits final decision and notes
exports.submitDecision = async (req, res) => {
  const { status, reviewNote } = req.body; // status: 'approved', 'rejected', or 'needs_changes'
  const project = await Project.findByIdAndUpdate(
    req.params.id,
    { status, reviewNote },
    { new: true }
  );
  res.json({ message: "Decision updated", project });
};