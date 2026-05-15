const nodemailer = require('nodemailer');

const gmailUser = process.env.GMAIL_USER;
const gmailPass = process.env.GMAIL_APP_PASSWORD;

let transporter = null;
if (gmailUser && gmailPass) {
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: Number(process.env.SMTP_PORT || 587),
    secure: false,
    requireTLS: true,
    auth: {
      user: gmailUser,
      pass: gmailPass,
    },
    connectionTimeout: 15000,
    greetingTimeout: 15000,
    socketTimeout: 20000,
  });
} else {
  console.warn('SMTP credentials (GMAIL_USER, GMAIL_APP_PASSWORD) missing. SMTP delivery disabled.');
}

async function sendViaResend(to, subject, text) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return null;

  const from = process.env.RESEND_FROM || 'SkillMart <onboarding@resend.dev>';
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from, to: [to], subject, text }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Resend error (${response.status}): ${body}`);
  }

  return true;
}

async function sendMail(to, subject, text) {
  if (process.env.RESEND_API_KEY) {
    return sendViaResend(to, subject, text);
  }

  if (!transporter) {
    throw new Error('Email service not configured (Missing SMTP or Resend credentials)');
  }

  await transporter.sendMail({
    from: gmailUser,
    to,
    subject,
    text,
  });
  return true;
}

exports.sendSubmissionConfirmation = async (userEmail, userName, projectName) => {
  const subject = `Submission Received: ${projectName}`;
  const text = `Hello ${userName},\n\nWe have successfully received your project submission for "${projectName}".\n\nAn expert analyst will review your project shortly. You will receive an email and push notification once the evaluation is complete.\n\nThank you for choosing SkillMart.\n\nBest regards,\nThe SkillMart Team`;

  try {
    await sendMail(userEmail, subject, text);
    console.log(`Submission confirmation sent to ${userEmail}`);
    return { ok: true };
  } catch (error) {
    console.error('Error sending submission confirmation:', error);
    return { ok: false };
  }
};

exports.sendVerificationEmail = async (userEmail, userName, code) => {
  const subject = 'Verify your SkillMart email';
  const text = `Hello ${userName},\n\nYour SkillMart verification code is: ${code}\n\nThis code expires in 15 minutes. If you did not request this, you can ignore this email.\n\nBest regards,\nThe SkillMart Team`;

  try {
    await sendMail(userEmail, subject, text);
    console.log(`Verification email sent to ${userEmail}`);
    return { ok: true };
  } catch (error) {
    console.error('Error sending verification email:', error);
    return { ok: false, error: error.message || 'Unknown email error' };
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

    await sendMail(userEmail, subject, text);
    console.log(`Notification email (${status}) sent to ${userEmail}`);
  } catch (error) {
    console.error('Error sending email:', error);
  }
};
