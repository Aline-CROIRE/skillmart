const User = require('../models/User');
const Project = require('../models/Project');
const Transaction = require('../models/Transaction');

exports.purchaseProject = async (req, res, next) => {
  try {
    const { projectId } = req.body;
    const buyer = await User.findById(req.user._id);
    const project = await Project.findById(projectId);

    if (!project) return res.status(404).json({ message: "Project not found" });
    if (buyer.walletBalance < project.price) return res.status(400).json({ message: "Insufficient RWF balance" });

    await User.findByIdAndUpdate(buyer._id, { 
      $inc: { walletBalance: -project.price },
      $push: { purchasedProjects: projectId }
    });

    await User.findByIdAndUpdate(project.sellerId, { $inc: { walletBalance: project.price } });

    await Transaction.create({
      buyer: buyer._id,
      seller: project.sellerId,
      project: projectId,
      amount: project.price
    });

    res.json({ message: "Success" });
  } catch (error) { next(error); }
};

exports.getMyLibrary = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).populate('purchasedProjects');
    res.json(user.purchasedProjects);
  } catch (error) { next(error); }
};

exports.getTransactionHistory = async (req, res, next) => {
  try {
    const transactions = await Transaction.find({
      $or: [{ buyer: req.user._id }, { seller: req.user._id }]
    })
    .populate('project', 'title')
    .populate('buyer', 'name')
    .populate('seller', 'name')
    .sort({ createdAt: -1 });
    
    res.json(transactions);
  } catch (error) { next(error); }
};