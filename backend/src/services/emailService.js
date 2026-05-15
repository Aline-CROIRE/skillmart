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

const getHtmlTemplate = (title, body, buttonLabel = null, buttonUrl = null) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f7f9; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    .header { background-color: #1e3a8a; padding: 30px; text-align: center; }
    .header h1 { color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 1px; }
    .content { padding: 40px; color: #334155; line-height: 1.6; }
    .content h2 { color: #1e293b; margin-top: 0; }
    .button-container { text-align: center; margin-top: 30px; }
    .button { display: inline-block; padding: 14px 28px; background-color: #2563eb; color: #ffffff !important; text-decoration: none; border-radius: 8px; font-weight: bold; }
    .footer { background-color: #f8fafc; padding: 20px; text-align: center; color: #94a3b8; font-size: 12px; }
    .code { font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #2563eb; margin: 20px 0; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header"><h1>SkillMart</h1></div>
    <div class="content">
      <h2>${title}</h2>
      ${body}
      ${buttonLabel && buttonUrl ? `<div class="button-container"><a href="${buttonUrl}" class="button">${buttonLabel}</a></div>` : ''}
    </div>
    <div class="footer">
      <p>&copy; 2026 SkillMart Inc. All rights reserved.</p>
      <p>Modern Solutions for Modern Skills.</p>
    </div>
  </div>
</body>
</html>
`;

async function sendMail(to, subject, text, html = null) {
  if (process.env.RESEND_API_KEY) {
    return sendViaResend(to, subject, text, html);
  }

  if (!transporter) {
    throw new Error('Email service not configured (Missing SMTP or Resend credentials)');
  }

  await transporter.sendMail({
    from: `SkillMart <${gmailUser}>`,
    to,
    subject,
    text,
    html: html || text,
  });
  return true;
}

exports.sendSubmissionConfirmation = async (userEmail, userName, projectName) => {
  const subject = `Submission Received: ${projectName}`;
  const text = `Hello ${userName},\n\nWe have successfully received your project submission for "${projectName}".\n\nAn expert analyst will review your project shortly. You will receive an email and push notification once the evaluation is complete.\n\nThank you for choosing SkillMart.\n\nBest regards,\nThe SkillMart Team`;
  
  const body = `
    <p>Hello <strong>${userName}</strong>,</p>
    <p>We have successfully received your project submission for <strong>"${projectName}"</strong>.</p>
    <p>An expert analyst will review your project shortly. You will receive an email and push notification once the evaluation is complete.</p>
    <p>Thank you for choosing SkillMart!</p>
  `;
  const html = getHtmlTemplate("Submission Received", body);

  try {
    await sendMail(userEmail, subject, text, html);
    console.log(`Submission confirmation sent to ${userEmail}`);
    return { ok: true };
  } catch (error) {
    console.error('Error sending submission confirmation:', error);
    return { ok: false };
  }
};

exports.sendVerificationEmail = async (userEmail, userName, code) => {
  const subject = 'Verify your SkillMart email';
  const text = `Hello ${userName},\n\nYour SkillMart verification code is: ${code}\n\nThis code expires in 15 minutes.`;

  const body = `
    <p>Hello <strong>${userName}</strong>,</p>
    <p>Welcome to SkillMart! Use the verification code below to complete your registration:</p>
    <div class="code">${code}</div>
    <p>This code expires in 15 minutes. If you did not request this, you can safely ignore this email.</p>
  `;
  const html = getHtmlTemplate("Email Verification", body);

  try {
    await sendMail(userEmail, subject, text, html);
    console.log(`Verification email sent to ${userEmail}`);
    return { ok: true };
  } catch (error) {
    console.error('Error sending verification email:', error);
    return { ok: false, error: error.message || 'Unknown email error' };
  }
};

exports.sendPasswordResetEmail = async (userEmail, userName, code) => {
  const subject = 'Reset your SkillMart password';
  const text = `Hello ${userName},\n\nYou requested to reset your password. Your recovery code is: ${code}`;

  const body = `
    <p>Hello <strong>${userName}</strong>,</p>
    <p>We received a request to reset your password. Use the secure code below to proceed:</p>
    <div class="code">${code}</div>
    <p>This code expires in 15 minutes. If you did not request this, please ensure your account is secure.</p>
  `;
  const html = getHtmlTemplate("Password Recovery", body);

  try {
    await sendMail(userEmail, subject, text, html);
    console.log(`Password reset email sent to ${userEmail}`);
    return { ok: true };
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return { ok: false };
  }
};

exports.sendNotificationEmail = async (userEmail, projectName, status) => {
  try {
    let subject = '';
    let text = '';

    if (status === 'approved') {
      subject = `Project Approved: Analytics for ${projectName} are out now!`;
      text = `Hello,\n\nAnalytics for "${projectName}" are out now! Open the app to view the expert evaluation and full data insights.\n\nBest regards,\nThe SkillMart Team`;
      
      const bodyContent = `
        <p>Exciting news! Analytics for <strong>"${projectName}"</strong> are now available.</p>
        <p>Our experts have completed their evaluation. You can now view the full data insights and performance score in the app.</p>
      `;
      html = getHtmlTemplate("Project Approved", bodyContent, "VIEW ANALYTICS", "https://skillmart.app/explore");

    } else if (status === 'rejected') {
      subject = `Update on Project: ${projectName}`;
      text = `Hello,\n\nWe are writing to inform you that the project "${projectName}" you bookmarked has been declined following our expert review.`;
      
      const bodyContent = `
        <p>We are writing to inform you that the project <strong>"${projectName}"</strong> has been declined following our expert review.</p>
        <p>While this specific project didn't meet our criteria, you can find other high-potential opportunities in the Explore section.</p>
      `;
      html = getHtmlTemplate("Project Update", bodyContent, "EXPLORE MORE", "https://skillmart.app/explore");

    } else if (status === 'needs_changes') {
      subject = `Action Required: Review Requested for ${projectName}`;
      text = `Hello,\n\nAn analyst has reviewed your submission for "${projectName}" and requested some additional information or changes.`;

      const bodyContent = `
        <p>An analyst has reviewed your submission for <strong>"${projectName}"</strong> and requested some additional information or changes.</p>
        <p>Please review the feedback and resubmit your project to continue the evaluation process.</p>
      `;
      html = getHtmlTemplate("Action Required", bodyContent, "REVIEW FEEDBACK", "https://skillmart.app/my-work");
    }

    if (!subject) return;

    await sendMail(userEmail, subject, text, html);
    console.log(`Notification email (${status}) sent to ${userEmail}`);
  } catch (error) {
    console.error('Error sending email:', error);
  }
};
