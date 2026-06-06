const fs = require('fs/promises');
const path = require('path');
const { randomUUID } = require('crypto');
const admin = require('firebase-admin');

let firebaseInitialized = false;

function initFirebaseStorage() {
  const bucketName = process.env.FIREBASE_STORAGE_BUCKET;
  if (!bucketName) return null;

  if (!firebaseInitialized) {
    const appOptions = { storageBucket: bucketName };
    const serviceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;

    if (serviceAccountBase64) {
      const serviceAccount = JSON.parse(
        Buffer.from(serviceAccountBase64, 'base64').toString('utf8'),
      );
      appOptions.credential = admin.credential.cert(serviceAccount);
    } else {
      appOptions.credential = admin.credential.applicationDefault();
    }

    admin.initializeApp(appOptions);
    firebaseInitialized = true;
  }

  return admin.storage().bucket(bucketName);
}

async function uploadImage({ buffer, contentType, outputName, uploadDir }) {
  const bucket = initFirebaseStorage();

  if (bucket) {
    const objectName = `immo-agence/${outputName}`;
    const downloadToken = randomUUID();
    const file = bucket.file(objectName);

    await file.save(buffer, {
      resumable: false,
      metadata: {
        contentType,
        metadata: {
          firebaseStorageDownloadTokens: downloadToken,
        },
      },
    });

    const encodedObjectName = encodeURIComponent(objectName);
    return {
      storage: 'firebase',
      url: `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedObjectName}?alt=media&token=${downloadToken}`,
    };
  }

  await fs.mkdir(uploadDir, { recursive: true });
  await fs.writeFile(path.join(uploadDir, outputName), buffer);

  return {
    storage: 'local',
    url: `/uploads/${outputName}`,
  };
}

module.exports = { uploadImage };
