const Project = require('../models/Project');
const mongoose = require('mongoose');

// 1. CREATE NEW
exports.createProject = async (req, res) => {
  try {
    const project = await Project.create({ ...req.body, status: 'pending' });
    res.status(201).json(project);
  } catch (error) { res.status(500).json({ message: error.message }); }
};

// 2. UPDATE EXISTING (Resubmission)
exports.updateProject = async (req, res) => {
  try {
    const { title, description, category, price, fileUrl } = req.body;
    const project = await Project.findByIdAndUpdate(
      req.params.id,
      { 
        title, description, category, price, fileUrl, 
        status: 'pending', // Reset to pending for Analyst to see
        reviewNote: ""     // Clear old feedback
      },
      { new: true }
    );
    res.json({ message: "Work resubmitted successfully", project });
  } catch (error) { res.status(500).json({ message: error.message }); }
};

// 3. MARKETPLACE VIEW
exports.getAllProjects = async (req, res) => {
  try {
    const projects = await Project.find({ status: 'approved' }).populate('sellerId', 'name');
    res.json(projects);
  } catch (error) { res.status(500).json({ message: error.message }); }
};

// 4. SELLER DASHBOARD
exports.getSellerProjects = async (req, res) => {
  try {
    const projects = await Project.find({ sellerId: req.params.sellerId });
    res.json(projects);
  } catch (error) { res.status(500).json({ message: error.message }); }
};