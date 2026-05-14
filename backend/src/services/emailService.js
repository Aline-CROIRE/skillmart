const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'skillmart13@gmail.com',
    pass: 'fncu ywoh wjiy lwvj' // Provided app password
  }
});

exports.sendApprovalEmail = async (userEmail, projectName) => {
  try {
    const mailOptions = {
      from: 'skillmart13@gmail.com',
      to: userEmail,
      subject: 'Project Approved: Analytics Now Available!',
      text: `Hello,\n\nThe project "${projectName}" you were watching has been approved and analyzed by our experts. You can now view the full details and analytics in the SkillMart app.\n\nBest regards,\nThe SkillMart Team`
    };

    await transporter.sendMail(mailOptions);
    console.log(`Email sent to ${userEmail}`);
  } catch (error) {
    console.error('Error sending email:', error);
  }
};
