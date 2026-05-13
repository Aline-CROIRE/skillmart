const Project = require('../models/Project');
const Analysis = require('../models/Analysis');

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
    );
    res.json({ message: `Project ${status} successfully`, project });
  } catch (error) { next(error); }
};