const Project = require('../models/Project');
const { addProjectToQueue } = require('../jobs/projectQueue');

exports.getSellerProjects = async (req, res, next) => {
  try {
    const projects = await Project.find({ sellerId: req.params.sellerId });
    res.status(200).json(projects);
  } catch (error) {
    next(error);
  }
};

exports.resubmitProject = async (req, res, next) => {
  try {
    const { title, description, category, fileUrl } = req.body;
    const project = await Project.findById(req.params.id);

    if (!project) {
      res.status(404);
      throw new Error('Project not found');
    }

    project.title = title || project.title;
    project.description = description || project.description;
    project.category = category || project.category;
    project.fileUrl = fileUrl || project.fileUrl;
    project.status = 'analyzing';

    await project.save();

    await addProjectToQueue({
      projectId: project._id,
      title: project.title,
      description: project.description,
      fileUrl: project.fileUrl
    });

    res.status(200).json(project);
  } catch (error) {
    next(error);
  }
};