# SkillMart 🚀

> Modern Solutions for Modern Skills. A comprehensive platform designed to bridge the gap between innovators, analysts, and shareholders.

SkillMart is a robust, full-stack hybrid application that allows creators to pitch business ideas and operational projects, while expert analysts review and verify submissions. Once approved, projects become available to the public and potential shareholders for investment and collaboration.

---

## 🌟 Key Features

### 🛡️ Multi-Tiered Access & Roles
- **Creators (Users):** Submit detailed project proposals, upload verification documents (RDB Certificates, Tax Clearances), and pitch videos.
- **Analysts:** Expert evaluators who review project submissions, request changes, and approve/decline projects.
- **Super Admins:** Command center access to oversee user directories, manage broadcast hubs, and orchestrate platform operations.

### 📱 Premium Mobile Experience
- **In-App Media Viewing:** View project PDFs, images, and pitch videos directly within the app context.
- **Real-Time Push Notifications:** Instant updates on project status (Approved, Declined, Needs Changes) powered by Firebase Cloud Messaging.
- **Secure Authentication:** Robust user registration with email verification, forgot-password flows, and secure JWT-based sessions.

### ⚙️ Powerful Backend Infrastructure
- **Automated Cloud Asset Management:** Direct integration with **Cloudinary** for seamless storage of images, PDFs, and MP4 videos.
- **Reliable Email Delivery:** Integrated with **Resend API** to ensure critical notifications (verification codes, security alerts) bypass cloud SMTP blocks.
- **Real-Time Gateway:** Built-in Socket.io support for real-time features and live telemetry.

---

## 🛠️ Technology Stack

**Frontend (Mobile App)**
- Framework: Flutter / Dart
- State Management: Provider
- Key Packages: `file_picker`, `url_launcher` (In-App Browser Mode), `cached_network_image`, `libphonenumber_js` validation.

**Backend (RESTful API)**
- Runtime: Node.js with Express.js
- Database: MongoDB with Mongoose ODM
- Authentication: JSON Web Tokens (JWT) & bcryptjs
- Third-Party Services: 
  - **Firebase Admin SDK** (Push Notifications)
  - **Cloudinary** (Media Storage)
  - **Resend** (Email Delivery)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0+)
- [Node.js](https://nodejs.org/) (v16.0+)
- [MongoDB](https://www.mongodb.com/) (Local or Atlas)
- Accounts for Firebase, Cloudinary, and Resend.

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure Environment Variables:
   Create a `.env` file in the root of the backend and add your credentials:
   ```env
   PORT=5000
   MONGO_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   RESEND_API_KEY=re_your_resend_key
   ```
4. Configure Firebase:
   Add your `firebase-service-account.json` to the `src/config/` directory.
5. Start the server:
   ```bash
   npm run dev
   ```
   *The server will automatically seed the Super Admin account and initialize the system configuration.*

### Mobile App Setup
1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```
2. Get Flutter packages:
   ```bash
   flutter pub get
   ```
3. Configure API Endpoint:
   In `lib/config/api_config.dart`, ensure the `productionUrl` or `defaultDevLanUrl` points to your backend.
4. Run the app:
   ```bash
   flutter run
   ```

---

## 🔐 Security & Deployment Notes

- **Git Security:** Sensitive files like `.env` and `firebase-service-account.json` are strictly ignored by `.gitignore`. 
- **Production Hosting:** When deploying to platforms like **Render**, always use the dashboard's "Environment Variables" and "Secret Files" features to inject configurations securely.
- **Data Protection:** The mobile app implements `FlutterWindowManagerPlus.FLAG_SECURE` on sensitive project screens to prevent unauthorized screen captures of intellectual property.

---

## 🤝 Contributing
Designed and developed with a focus on modern aesthetics, dynamic micro-animations, and robust data integrity. 
