# CloudFront Distribution

Terraform stack that creates a CloudFront CDN distribution in front of the S3 website bucket, providing HTTPS and edge caching.

## What It Creates

- CloudFront distribution with OAC (Origin Access Control)
- S3 bucket policy allowing CloudFront-only access
- Automatic cache invalidation on content or distribution changes
- Custom error responses (403/404 → error page)

## Usage

Deploy the S3 stack first, then:

```bash
terraform init -backend-config=backend/dev.conf
terraform plan -var-file=../env/dev.tfvars
terraform apply -var-file=../env/dev.tfvars
```

## Variables

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `region` | string | — | yes | AWS region |
| `state_bucket` | string | — | yes | S3 bucket holding Terraform state files |
| `env` | string | — | yes | Environment name (dev, staging, prod) |
| `index_document` | string | `index.html` | no | Index document filename |
| `error_document` | string | `error.html` | no | Error document filename |
| `tags` | map(string) | `{}` | no | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `cloudfront_domain_name` | CloudFront distribution domain (HTTPS) |
| `cloudfront_distribution_id` | Distribution ID |
| `cloudfront_distribution_arn` | Distribution ARN |

## Cross-Stack Data

This stack reads S3 bucket details from the S3 stack's remote state via `terraform_remote_state` in `data.tf`:

- `bucket_id` — bucket name for the OAC policy
- `bucket_arn` — bucket ARN for the policy resource
- `bucket_regional_domain_name` — CloudFront origin domain
- `content_hash` — triggers cache invalidation on content changes

The state key is dynamically built as `s3/<env>/terraform.tfstate`.

## Module

Uses [`terraform-aws-modules/cloudfront/aws`](https://registry.terraform.io/modules/terraform-aws-modules/cloudfront/aws/6.4.0) v6.4.0.

## Configuration Details

- Price class: `PriceClass_100` (US, Canada, Europe)
- Viewer protocol: redirect HTTP to HTTPS
- TLS minimum: `TLSv1.2_2025`
- Caching: Managed-CachingOptimized policy
- Compression: enabled
- IPv6: enabled

## Cache Invalidation

The `terraform_data.cloudfront_invalidation` resource triggers `aws cloudfront create-invalidation` when either:
- S3 content changes (via `content_hash` from remote state)
- CloudFront distribution config changes (via `distribution_etag`)

For content-only updates via CI/CD, the `content-deploy.yml` workflow handles invalidation directly without Terraform.
