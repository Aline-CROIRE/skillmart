const User = require('../models/User');
const SystemConfig = require('../models/SystemConfig');
const { cloudinary } = require('./cloudinary');
const path = require('path');
const fs = require('fs');

const seedAdmin = async () => {
  try {
    // 1. Seed Admin
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
    } else if (adminExists.role !== 'Admin') {
      adminExists.role = 'Admin';
      await adminExists.save();
      console.log('✅ User promoted to Admin: skillmart13@gmail.com');
    }

    // 2. Seed System Logo
    const logoConfig = await SystemConfig.findOne({ key: 'system_logo_url' });
    if (!logoConfig) {
      const logoPath = path.resolve(__dirname, '../../../mobile/assets/backgrounded logo.png');
      
      if (fs.existsSync(logoPath)) {
        console.log('📤 Uploading system logo to Cloudinary...');
        const result = await cloudinary.uploader.upload(logoPath, {
          folder: 'skillmart/system',
          public_id: 'system_logo',
          overwrite: true,
          resource_type: 'auto'
        });

        await SystemConfig.create({
          key: 'system_logo_url',
          value: result.secure_url
        });
        console.log('✅ System logo uploaded and configured:', result.secure_url);
      } else {
        console.warn('⚠️ System logo file not found at:', logoPath);
      }
    }
  } catch (error) {
    console.error('❌ Error seeding system data:', error);
  }
};

module.exports = seedAdmin;
