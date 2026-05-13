const User = require('../models/User');
const Project = require('../models/Project');
const Transaction = require('../models/Transaction');

exports.purchaseProject = async (req, res, next) => {
  try {
    const { projectId } = req.body;
    const buyer = req.user;
    const project = await Project.findById(projectId).populate('sellerId');

    if (buyer.walletBalance < project.price) {
      return res.status(400).json({ message: 'Insufficient funds' });
    }

    // Atomic Balance Update
    await User.findByIdAndUpdate(buyer._id, { $inc: { walletBalance: -project.price }, $push: { purchasedProjects: projectId } });
    await User.findByIdAndUpdate(project.sellerId._id, { $inc: { walletBalance: project.price } });
    await Project.findByIdAndUpdate(projectId, { $inc: { 'stats.sales': 1 } });

    await Transaction.create({ buyer: buyer._id, seller: project.sellerId._id, project: projectId, amount: project.price });

    res.json({ message: 'Purchase successful' });
  } catch (error) {
    next(error);
  }
};