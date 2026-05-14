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

    // 1. Deduct from buyer, add to library
    await User.findByIdAndUpdate(buyer._id, { 
      $inc: { walletBalance: -project.price },
      $push: { purchasedProjects: projectId }
    });

    // 2. Add to seller
    await User.findByIdAndUpdate(project.sellerId, { $inc: { walletBalance: project.price } });

    // 3. Log Transaction
    await Transaction.create({
      buyer: buyer._id,
      seller: project.sellerId,
      project: projectId,
      amount: project.price
    });

    res.json({ message: "Purchase successful! Project added to library." });
  } catch (error) { next(error); }
};

exports.getMyLibrary = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).populate('purchasedProjects');
    res.json(user.purchasedProjects);
  } catch (error) { next(error); }
};