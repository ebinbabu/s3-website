# S3 Static Website Bucket

Terraform stack that creates an S3 bucket configured for static website hosting and uploads initial content.

## What It Creates

- S3 bucket with website hosting enabled
- AES256 server-side encryption
- Versioning enabled
- `index.html` and `error.html` uploaded from local files

## Usage

```bash
terraform init -backend-config=backend/dev.conf
terraform plan -var-file=../env/dev.tfvars
terraform apply -var-file=../env/dev.tfvars
```

## Variables

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `region` | string | `ap-south-1` | no | AWS region |
| `bucket_name` | string | — | yes | S3 bucket name |
| `index_document` | string | `index.html` | no | Index document filename |
| `error_document` | string | `error.html` | no | Error document filename |
| `index_html_path` | string | — | yes | Path to index HTML file |
| `error_html_path` | string | — | yes | Path to error HTML file |
| `tags` | map(string) | `{}` | no | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `website_endpoint` | S3 website endpoint (HTTP only) |
| `bucket_arn` | ARN of the S3 bucket |
| `bucket_id` | Name of the S3 bucket |
| `bucket_regional_domain_name` | Regional domain name for CloudFront origin |
| `bucket_region` | Region of the S3 bucket |
| `content_hash` | Combined hash of content files (triggers CloudFront invalidation) |

## Module

Uses [`terraform-aws-modules/s3-bucket/aws`](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/5.10.0) v5.10.0.

## Notes

- Content files live in `content/<env>/` and are referenced via `index_html_path` and `error_html_path` in tfvars
- The `etag` attribute on `aws_s3_object` ensures Terraform detects file changes and re-uploads only when content changes
- For day-to-day content updates, prefer `aws s3 sync` over Terraform (faster, no state risk)
