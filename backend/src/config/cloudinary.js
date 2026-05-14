const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'ddknoowmz', 
  api_key: process.env.CLOUDINARY_API_KEY || '198839267516421',
  api_secret: process.env.CLOUDINARY_API_SECRET || 'BobxIxzSfV72io1z2H6liqCNpsQ'
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: async (req, file) => {
    let folder = 'skillmart/others';
    let format = 'png';
    
    if (file.mimetype.includes('image')) folder = 'skillmart/images';
    if (file.mimetype.includes('pdf')) {
      folder = 'skillmart/documents';
      format = 'pdf';
    }
    if (file.mimetype.includes('video')) {
      folder = 'skillmart/videos';
      format = 'mp4';
    }

    return {
      folder: folder,
      format: format,
      public_id: Date.now() + '-' + file.originalname.split('.')[0],
      resource_type: 'auto'
    };
  },
});

const cloudinaryUpload = multer({ storage: storage });

module.exports = cloudinaryUpload;
