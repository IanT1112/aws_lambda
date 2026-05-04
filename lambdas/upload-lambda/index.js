const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { randomUUID } = require("crypto");

const s3 = new S3Client({ region: process.env.AWS_REGION || "us-east-1" });

const BUCKET   = process.env.S3_BUCKET;
const PREFIX   = process.env.UPLOAD_PREFIX || "uploads/";
const MAX_SIZE = 10 * 1024 * 1024;
const ALLOWED  = ["image/jpeg", "image/png", "image/gif", "image/webp"];

exports.handler = async (event) => {
  try {
    let imageBuffer;
    let contentType;

    if (event.isBase64Encoded) {
      const body = JSON.parse(Buffer.from(event.body, "base64").toString("utf8"));
      contentType = body.contentType || "image/jpeg";
      imageBuffer = Buffer.from(body.image, "base64");
    } else {
      const body = typeof event.body === "string" ? JSON.parse(event.body) : event.body;
      contentType = body.contentType || "image/jpeg";
      imageBuffer = Buffer.from(body.image, "base64");
    }

    if (!ALLOWED.includes(contentType)) {
      return respond(400, { error: `Content type not allowed: ${contentType}` });
    }

    if (imageBuffer.length > MAX_SIZE) {
      return respond(400, { error: "Image exceeds maximum size of 10 MB" });
    }

    const extMap = {
      "image/jpeg": "jpg",
      "image/png":  "png",
      "image/gif":  "gif",
      "image/webp": "webp",
    };

    const extension = extMap[contentType] || "jpg";
    const key = `${PREFIX}${randomUUID()}.${extension}`;

    await s3.send(new PutObjectCommand({
      Bucket:      BUCKET,
      Key:         key,
      Body:        imageBuffer,
      ContentType: contentType,
    }));

    return respond(200, {
      message: "Image uploaded successfully",
      key,
      bucket: BUCKET,
    });

  } catch (err) {
    return respond(500, { error: "Internal server error", detail: err.message });
  }
};

function respond(statusCode, body) {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
    body: JSON.stringify(body),
  };
}
