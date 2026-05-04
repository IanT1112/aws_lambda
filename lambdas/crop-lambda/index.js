const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");

const s3 = new S3Client({ region: process.env.AWS_REGION || "us-east-1" });

const BUCKET           = process.env.S3_BUCKET;
const PROCESSED_PREFIX = process.env.PROCESSED_PREFIX || "processed/";
const SIZE             = 40;

exports.handler = async (event) => {
  for (const record of event.Records) {
    const body = JSON.parse(record.body);

    if (body.Event === "s3:TestEvent") {
      continue;
    }

    const s3Event  = body.Records[0];
    const s3Key    = decodeURIComponent(s3Event.s3.object.key.replace(/\+/g, " "));
    const s3Bucket = s3Event.s3.bucket.name;

    const getResult = await s3.send(new GetObjectCommand({
      Bucket: s3Bucket,
      Key:    s3Key,
    }));

    const chunks = [];
    for await (const chunk of getResult.Body) {
      chunks.push(chunk);
    }
    const imageBuffer = Buffer.concat(chunks);

    const circleMask = Buffer.from(
      `<svg width="${SIZE}" height="${SIZE}">
        <circle cx="${SIZE / 2}" cy="${SIZE / 2}" r="${SIZE / 2}" fill="white"/>
      </svg>`
    );

    const processedBuffer = await sharp(imageBuffer)
      .resize(SIZE, SIZE, { fit: "cover", position: "center" })
      .composite([{ input: circleMask, blend: "dest-in" }])
      .png()
      .toBuffer();

    const originalFilename = s3Key.split("/").pop().split(".")[0];
    const outputKey        = `${PROCESSED_PREFIX}${originalFilename}_circular.png`;

    await s3.send(new PutObjectCommand({
      Bucket:      BUCKET,
      Key:         outputKey,
      Body:        processedBuffer,
      ContentType: "image/png",
    }));
  }

  return { batchItemFailures: [] };
};
