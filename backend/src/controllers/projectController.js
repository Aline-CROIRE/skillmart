const Project = require('../models/Project');
const { addProjectToQueue } = require('../jobs/projectQueue');

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
      status: 'analyzing'
    });

    await addProjectToQueue({
      projectId: project._id,
      title: project.title,
      description: project.description,
      fileUrl: project.fileUrl
    });

    res.status(201).json({
      message: 'Project submitted and queued for analysis',
      project
    });
  } catch (error) {
    next(error);
  }
};