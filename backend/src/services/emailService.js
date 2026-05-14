const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'skillmart13@gmail.com',
    pass: 'fncu ywoh wjiy lwvj' 
  }
});

exports.sendVerificationEmail = async (userEmail, token) => {
  const url = `https://skillmart-api.onrender.com/api/auth/verify/${token}`;
  try {
    const mailOptions = {
      from: 'skillmart13@gmail.com',
      to: userEmail,
      subject: 'Verify Your SkillMart Account',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #3f51b5;">Welcome to SkillMart!</h2>
          <p>Please click the button below to verify your email address and activate your account:</p>
          <a href="${url}" style="display: inline-block; padding: 12px 24px; background-color: #3f51b5; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; margin-top: 10px;">Verify Email</a>
          <p style="margin-top: 20px; color: #666; font-size: 12px;">If you didn't create an account, you can safely ignore this email.</p>
        </div>
      `
    };
    await transporter.sendMail(mailOptions);
    console.log(`Verification email sent to ${userEmail}`);
  } catch (error) {
    console.error('Error sending verification email:', error);
  }
};

exports.sendNotificationEmail = async (userEmail, projectName, status) => {
  try {
    let subject = '';
    let text = '';

    if (status === 'approved') {
      subject = `Project Approved: Analytics for ${projectName} are out now!`;
      text = `Hello,\n\nAnalytics for "${projectName}" are out now! Open the app to view the expert evaluation and full data insights.\n\nBest regards,\nThe SkillMart Team`;
    } else if (status === 'rejected') {
      subject = `Update on Project: ${projectName}`;
      text = `Hello,\n\nWe are writing to inform you that the project "${projectName}" you bookmarked has been declined following our expert review.\n\nYou can find other high-potential projects in the Explore Excellence section of the app.\n\nBest regards,\nThe SkillMart Team`;
    } else if (status === 'needs_changes') {
      subject = `Action Required: Review Requested for ${projectName}`;
      text = `Hello,\n\nAn analyst has reviewed your submission for "${projectName}" and requested some additional information or changes.\n\nPlease open the app, go to "My Work", and check the feedback to resubmit your project.\n\nBest regards,\nThe SkillMart Team`;
    }

    if (!subject) return;

    const mailOptions = {
      from: 'skillmart13@gmail.com',
      to: userEmail,
      subject: subject,
      text: text
    };

    await transporter.sendMail(mailOptions);
    console.log(`Notification email (${status}) sent to ${userEmail}`);
  } catch (error) {
    console.error('Error sending email:', error);
  }
};
