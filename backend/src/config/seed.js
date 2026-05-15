const User = require('../models/User');

const seedAdmin = async () => {
  try {
    const adminEmail = 'skillmart13@gmail.com';
    const adminPassword = 'Admin@123';

    const adminExists = await User.findOne({ email: adminEmail });

    if (!adminExists) {
      await User.create({
        name: 'Super Admin',
        email: adminEmail,
        password: adminPassword,
        role: 'Admin',
        emailVerified: true
      });
      console.log('✅ Default Admin account created: skillmart13@gmail.com');
    } else {
      // Ensure the existing account has Admin role
      if (adminExists.role !== 'Admin') {
        adminExists.role = 'Admin';
        await adminExists.save();
        console.log('✅ User promoted to Admin: skillmart13@gmail.com');
      }
    }
  } catch (error) {
    console.error('❌ Error seeding Admin account:', error);
  }
};

module.exports = seedAdmin;
