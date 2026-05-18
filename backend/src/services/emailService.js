const nodemailer = require('nodemailer');
const dns = require('dns');
const SystemConfig = require('../models/SystemConfig');

// Force Node.js to prefer IPv4 over IPv6 globally
// This prevents ENETUNREACH errors on cloud hosting (like Render) which typically lack IPv6 outbound routing
if (dns.setDefaultResultOrder) {
  dns.setDefaultResultOrder('ipv4first');
}

const gmailUser = process.env.GMAIL_USER;
const gmailPass = process.env.GMAIL_APP_PASSWORD;
const resendKey = process.env.RESEND_API_KEY;

// Pre-resolve smtp.gmail.com to IPv4 A-records at startup to completely bypass OS-level getaddrinfo IPv6 bugs
let gmailSmtpIp = '74.125.193.108'; // Solid default Gmail SMTP IPv4 address
dns.resolve4('smtp.gmail.com', (err, addresses) => {
  if (!err && addresses && addresses.length > 0) {
    gmailSmtpIp = addresses[0];
    console.log(`[DNS] Pre-resolved smtp.gmail.com strictly to IPv4 A-record: ${gmailSmtpIp}`);
  } else {
    console.error(`[DNS] Failed to resolve4 smtp.gmail.com, using fallback ${gmailSmtpIp}:`, err);
  }
});

let transporter = null;
if (gmailUser && gmailPass) {
  const smtpPort = Number(process.env.SMTP_PORT || 587);
  const isSecure = smtpPort === 465;

  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || gmailSmtpIp,
    port: smtpPort,
    secure: isSecure,
    auth: {
      user: gmailUser,
      pass: gmailPass,
    },
    tls: {
      rejectUnauthorized: false, // Prevents certificate handshake errors on cloud platforms like Render
      servername: 'smtp.gmail.com', // Keeps SNI working with the pre-resolved IPv4 IP address
    },
    connectionTimeout: 10000, // Prevents infinite loading if SMTP ports are blocked by host
    socketTimeout: 10000,
    greetingTimeout: 10000,
  });
}

async function sendViaResend(to, subject, text, html = null) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return null;

  const from = process.env.RESEND_FROM || 'SkillMart <onboarding@resend.dev>';
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from, to: [to], subject, text, html: html || text }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Resend error (${response.status}): ${body}`);
  }
  return true;
}

const getHtmlTemplate = (title, body, logoUrl = null) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f7f9; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    .header { background-color: #1e3a8a; padding: 40px 30px; text-align: center; }
    .logo-box { background: white; width: 60px; height: 60px; border-radius: 50%; margin: 0 auto 15px; display: flex; align-items: center; justify-content: center; overflow: hidden; }
    .logo-img { width: 100%; height: 100%; object-fit: cover; }
    .logo-text { font-weight: bold; color: #1e3a8a; font-size: 24px; }
    .header h1 { color: #ffffff; margin: 0; font-size: 24px; letter-spacing: 1px; text-transform: uppercase; }
    .content { padding: 40px; color: #334155; line-height: 1.6; }
    .content h2 { color: #1e293b; margin-top: 0; }
    .footer { background-color: #f8fafc; padding: 20px; text-align: center; color: #94a3b8; font-size: 12px; }
    .code { font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1e3a8a; margin: 20px 0; text-align: center; padding: 15px; background: #f1f5f9; border-radius: 8px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-box">
        ${logoUrl ? `<img src="${logoUrl}" alt="Logo" class="logo-img">` : '<span class="logo-text">SM</span>'}
      </div>
      <h1>SkillMart</h1>
    </div>
    <div class="content">
      <h2>${title}</h2>
      ${body}
      <p style="margin-top: 30px; font-size: 14px; color: #64748b;"><em>Please open the SkillMart mobile app to continue.</em></p>
    </div>
    <div class="footer">
      <p>&copy; 2026 SkillMart Inc. All rights reserved.</p>
      <p>Modern Solutions for Modern Skills.</p>
    </div>
  </div>
</body>
</html>
`;

const getLogoUrl = async () => {
  try {
    const config = await SystemConfig.findOne({ key: 'system_logo_url' });
    return config ? config.value : null;
  } catch (e) { return null; }
};

exports.getHtmlTemplate = getHtmlTemplate;
exports.getLogoUrl = getLogoUrl;
exports.sendMail = sendMail;

async function sendMail(to, subject, text, html = null) {
  // Bypassed Resend to always use secure Gmail SMTP on port 587 (matching Java configuration)
  /*
  if (process.env.RESEND_API_KEY) {
    return sendViaResend(to, subject, text, html);
  }
  */

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
  const logoUrl = await getLogoUrl();
  const html = getHtmlTemplate("Submission Received", body, logoUrl);

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
  const logoUrl = await getLogoUrl();
  const html = getHtmlTemplate("Email Verification", body, logoUrl);

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
  const logoUrl = await getLogoUrl();
  const html = getHtmlTemplate("Password Recovery", body, logoUrl);

  try {
    await sendMail(userEmail, subject, text, html);
    console.log(`Password reset email sent to ${userEmail}`);
    return { ok: true };
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return { ok: false };
  }
};

exports.sendAnalystCredentialsEmail = async (userEmail, userName, password) => {
  const subject = 'Your SkillMart Analyst Credentials';
  const text = `Hello ${userName},\n\nYou have been added as an Analyst on SkillMart.\n\nLogin Email: ${userEmail}\nTemporary Password: ${password}\n\nPlease login and complete your profile (upload ID and picture) to start working.`;

  const body = `
    <p>Hello <strong>${userName}</strong>,</p>
    <p>Welcome to the expert team! You have been added as an <strong>Analyst</strong> on SkillMart.</p>
    <p>Use the credentials below to login to your new account:</p>
    <div style="background: #f1f5f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <p style="margin: 0;"><strong>Email:</strong> ${userEmail}</p>
      <p style="margin: 10px 0 0 0;"><strong>Password:</strong> ${password}</p>
    </div>
    <p><strong>Next Steps:</strong></p>
    <ol>
      <li>Login with these credentials.</li>
      <li>Verify your email address.</li>
      <li>Upload your <strong>National ID</strong> and <strong>Profile Picture</strong>.</li>
    </ol>
    <p>Once your profile is confirmed by the Super Admin, you can start evaluating projects.</p>
  `;
  const logoUrl = await getLogoUrl();
  const html = getHtmlTemplate("Welcome to the Team", body, logoUrl);

  try {
    await sendMail(userEmail, subject, text, html);
    console.log(`Analyst credentials email sent to ${userEmail}`);
    return { ok: true };
  } catch (error) {
    console.error('Error sending analyst credentials email:', error);
    return { ok: false };
  }
};

exports.sendNotificationEmail = async (userEmail, projectName, status) => {
  try {
    let subject = '';
    let text = '';
    let html = '';
    const logoUrl = await getLogoUrl();

    if (status === 'approved') {
      subject = `Project Approved: Analytics for ${projectName} are out now!`;
      text = `Hello,\n\nAnalytics for "${projectName}" are out now! Open the app to view the expert evaluation and full data insights.\n\nBest regards,\nThe SkillMart Team`;
      
      const bodyContent = `
        <p>Exciting news! Analytics for <strong>"${projectName}"</strong> are now available.</p>
        <p>Our experts have completed their evaluation. You can now view the full data insights and performance score in the app.</p>
      `;
      html = getHtmlTemplate("Project Approved", bodyContent, logoUrl);

    } else if (status === 'rejected') {
      subject = `Update on Project: ${projectName}`;
      text = `Hello,\n\nWe are writing to inform you that the project "${projectName}" you bookmarked has been declined following our expert review.`;
      
      const bodyContent = `
        <p>We are writing to inform you that the project <strong>"${projectName}"</strong> has been declined following our expert review.</p>
        <p>While this specific project didn't meet our criteria, you can find other high-potential opportunities in the Explore section.</p>
      `;
      html = getHtmlTemplate("Project Update", bodyContent, logoUrl);

    } else if (status === 'needs_changes') {
      subject = `Action Required: Review Requested for ${projectName}`;
      text = `Hello,\n\nAn analyst has reviewed your submission for "${projectName}" and requested some additional information or changes.`;

      const bodyContent = `
        <p>An analyst has reviewed your submission for <strong>"${projectName}"</strong> and requested some additional information or changes.</p>
        <p>Please review the feedback and resubmit your project to continue the evaluation process.</p>
      `;
      html = getHtmlTemplate("Action Required", bodyContent, logoUrl);
    }

    if (!subject) return;

    await sendMail(userEmail, subject, text, html);
    console.log(`Notification email (${status}) sent to ${userEmail}`);
  } catch (error) {
    console.error('Error sending email:', error);
  }
};

exports.sendSecurityAlertEmail = async (userEmail, title, message) => {
  try {
    const subject = `Security Alert: ${title}`;
    const text = `Security Alert: ${title}\n\n${message}\n\nIf you did not expect this, please secure your account immediately.`;
    
    const body = `
      <p style="color: #e11d48; font-weight: bold;">Security Alert</p>
      <p><strong>${title}</strong></p>
      <p>${message}</p>
      <p style="margin-top: 20px; font-size: 13px; background: #fff1f2; padding: 15px; border-radius: 8px; border-left: 4px solid #e11d48;">
        If you did not authorize this action, please contact support or reset your password immediately to protect your account.
      </p>
    `;
    const logoUrl = await getLogoUrl();
    const html = getHtmlTemplate("Security Notification", body, logoUrl);

    await sendMail(userEmail, subject, text, html);
    console.log(`Security email sent to ${userEmail}`);
  } catch (error) {
    console.error('Error sending security email:', error);
  }
};
