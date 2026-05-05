# Image Processor — Infrastructure as Code

Serverless image processing architecture deployed on AWS using Terraform, supporting three independent environments: `dev`, `qa`, and `prod`.

---

## Architecture Overview

```
Client → API Gateway HTTP v2 (POST /upload) → upload-lambda → S3 (uploads/)
                                                                     ↓
                                                              SQS Queue
                                                                     ↓
                                                          crop-lambda → S3 (processed/)
```

### AWS Services

| Service | Configuration |
|---|---|
| API Gateway HTTP v2 | Route: POST /upload, CORS enabled, TLS 1.2+, throttling 10,000 rps |
| Lambda (upload) | Runtime: nodejs20.x, Handler: index.handler, Env vars: S3_BUCKET, UPLOAD_PREFIX |
| Lambda (crop) | Runtime: nodejs20.x, Handler: index.handler, Memory: 512 MB, Timeout: 60s |
| S3 | SSE-AES256, versioning enabled, lifecycle: uploads 30d / processed 90d |
| SQS | Standard queue, visibility timeout 360s, DLQ after 3 failed attempts |
| VPC | CIDR 10.0.0.0/16, 2 public subnets, 2 private subnets, 2 NAT Gateways |
| VPC Endpoints | S3 Gateway Endpoint (free), SQS Interface Endpoint |
| IAM | Least-privilege roles per lambda |
| CloudWatch | Log groups with 14-day retention, DLQ alarm |

---

## Project Structure

```
image-processor/
├── modules/
│   ├── api_gateway/
│   ├── cloudwatch/
│   ├── iam/
│   ├── lambda/
│   ├── networking/
│   ├── s3/
│   └── sqs/
├── environments/
│   ├── dev/
│   ├── qa/
│   └── prod/
├── lambdas/
│   ├── upload-lambda/
│   └── crop-lambda/
└── README.md
```

---

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with valid credentials
- Node.js >= 20.x

---

## Initial Setup

Install lambda dependencies before the first deployment:

```bash
cd lambdas/upload-lambda
npm install

cd ../crop-lambda
npm install
```

Update the `suffix` value in each `terraform.tfvars` file (dev, qa, prod) to ensure a globally unique S3 bucket name:

```hcl
suffix = "your-unique-suffix"
```

---

## Deployment

### DEV

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### QA

```bash
cd environments/qa
terraform init
terraform plan
terraform apply
```

### PROD

```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

Upon completion, the output will display:

```
api_endpoint = "https://<id>.execute-api.us-east-1.amazonaws.com/upload"
bucket_name  = "image-processor-<env>-images-<suffix>"
```

---

## Environment Differences

| Variable | DEV | QA | PROD |
|---|---|---|---|
| `upload_lambda_memory` | 128 MB | 256 MB | 256 MB |
| `crop_lambda_memory` | 256 MB | 512 MB | 512 MB |
| S3 bucket | image-processor-dev-... | image-processor-qa-... | image-processor-prod-... |
| SQS queue | ...-dev-image-queue | ...-qa-image-queue | ...-prod-image-queue |

---

## Testing

```bash
BASE64=$(base64 -w 0 image.jpg)

curl -X POST https://<api-endpoint>/upload \
  -H "Content-Type: application/json" \
  -d "{\"image\": \"$BASE64\", \"contentType\": \"image/jpeg\"}"
```

Expected response:

```json
{
  "message": "Image uploaded successfully",
  "key": "uploads/<uuid>.jpg",
  "bucket": "image-processor-dev-images-<suffix>"
}
```

---

## Destroy Resources

```bash
cd environments/dev
terraform destroy
```

> **Note:** Some resources require manual deletion before or after `terraform destroy`:
> - S3 bucket: must be emptied manually if `force_destroy` is not set.
> - CloudWatch Log Groups: may persist as remnants after destroy.
> - SQS in-flight messages: the queue may delay deletion if messages are being processed.
>
> Document any errors encountered during destroy as part of the lab report.

---

## Allowed Image Formats

`image/jpeg` · `image/png` · `image/gif` · `image/webp`

Maximum upload size: **10 MB**

Output format: **40×40 px circular PNG with transparent background**
