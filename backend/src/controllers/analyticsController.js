const Project = require('../models/Project');
const Transaction = require('../models/Transaction');

exports.getGlobalTrends = async (req, res, next) => {
  try {
    const categoryTrends = await Project.aggregate([
      { $group: { _id: "$category", totalSales: { $sum: "$stats.sales" }, totalViews: { $sum: "$stats.views" } } }
    ]);

    const totalRevenue = await Transaction.aggregate([{ $group: { _id: null, total: { $sum: "$amount" } } }]);

    res.json({ categoryTrends, totalRevenue: totalRevenue[0]?.total || 0 });
  } catch (error) {
    next(error);
  }
};