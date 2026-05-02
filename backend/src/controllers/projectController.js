const Project = require('../models/Project');

exports.uploadFile = (req, res) => {
  if (!req.file) {
    res.status(400);
    throw new Error('No file uploaded');
  }
  res.status(200).json({
    message: 'File uploaded successfully',
    fileUrl: `/uploads/${req.file.filename}`,
  });
};

exports.createProject = async (req, res, next) => {
  try {
    const { title, description, category, fileUrl, sellerId } = req.body;

    if (!title || !description || !category || !sellerId) {
      res.status(400);
      throw new Error('Please provide all required fields');
    }

    const project = await Project.create({
      title,
      description,
      category,
      fileUrl,
      sellerId,
    });

    res.status(201).json(project);
  } catch (error) {
    next(error);
  }
};