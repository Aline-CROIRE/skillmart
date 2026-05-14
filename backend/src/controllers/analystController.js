const Project = require('../models/Project');

exports.getPendingQueue = async (req, res) => {
  try {
    // Show projects that are fresh (pending) or being revised (needs_changes)
    const projects = await Project.find({ 
      status: { $in: ['pending', 'needs_changes'] } 
    }).populate('sellerId', 'name');
    res.json(projects);
  } catch (error) { res.status(500).json({ message: error.message }); }
};

exports.submitDecision = async (req, res) => {
  try {
    const { status, reviewNote } = req.body; 
    // Status can be: 'approved', 'rejected', or 'needs_changes'
    const project = await Project.findByIdAndUpdate(
      req.params.id,
      { status, reviewNote },
      { new: true }
    );
    res.json({ message: `Decision: ${status} recorded.`, project });
  } catch (error) { res.status(500).json({ message: error.message }); }
};