# AWS Static Website Infrastructure

S3 + CloudFront static website hosting with Terraform, bootstrapped via CloudFormation, and automated with GitHub Actions.

## Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Browser    │────▶│   CloudFront     │────▶│   S3 Bucket     │
│              │     │   (HTTPS/CDN)    │     │   (Website)     │
└─────────────┘     │   OAC + TLS 1.2  │     │   AES256 + Ver. │
                    └──────────────────┘     └─────────────────┘
```

## Project Structure

```
.
├── bootstrap/                  # CloudFormation — foundational resources
│   ├── terraform-state-bucket.yaml   # S3 state bucket with object lock
│   ├── github-oidc.yaml              # GitHub Actions OIDC + IAM role
│   └── README.md
├── s3/                         # Terraform — S3 website bucket + content
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── backend/dev.conf
│   └── README.md
├── cloudfront/                 # Terraform — CloudFront distribution + OAC
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── data.tf
│   ├── backend/dev.conf
│   └── README.md
├── content/                    # Static website HTML files
│   └── dev/
│       ├── index.html
│       └── error.html
├── env/                        # Environment-specific variables
│   └── dev.tfvars
└── .github/workflows/          # CI/CD pipelines
    ├── infrastructure.yml      # Terraform plan/apply
    └── content-deploy.yml      # S3 sync + CloudFront invalidation
```

## Prerequisites

- AWS CLI configured
- Terraform >= 1.14
- Docker (for Terraform MCP server, optional)

## Deploy Order

### 1. Bootstrap (one-time)

```bash
# State bucket
aws cloudformation deploy \
  --template-file bootstrap/terraform-state-bucket.yaml \
  --stack-name terraform-state-bucket \
  --parameter-overrides BucketName=my-terraform-state-bucket

# GitHub OIDC (if using CI/CD)
aws cloudformation deploy \
  --template-file bootstrap/github-oidc.yaml \
  --stack-name github-oidc \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOrg=your-org \
    GitHubRepo=your-repo \
    StateBucketName=my-terraform-state-bucket \
    WebsiteBucketName=my-static-website-dev
```

### 2. S3 Bucket

```bash
terraform -chdir=s3 init -backend-config=backend/dev.conf
terraform -chdir=s3 apply -var-file=../env/dev.tfvars
```

### 3. CloudFront Distribution

```bash
terraform -chdir=cloudfront init -backend-config=backend/dev.conf
terraform -chdir=cloudfront apply -var-file=../env/dev.tfvars
```

### 4. Content Updates (day-to-day)

```bash
aws s3 sync content/dev/ s3://my-static-website-dev/ --delete
aws cloudfront create-invalidation --distribution-id <ID> --paths '/*'
```

## Adding a New Environment

1. Create `env/prod.tfvars`
2. Create `s3/backend/prod.conf` and `cloudfront/backend/prod.conf`
3. Create `content/prod/` with HTML files
4. Deploy with `--backend-config=backend/prod.conf` and `-var-file=../env/prod.tfvars`

## CI/CD

Two GitHub Actions workflows handle automation:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `infrastructure.yml` | Changes to `s3/`, `cloudfront/`, `env/` | Terraform plan on PR, apply on merge |
| `content-deploy.yml` | Changes to `content/` | S3 sync + CloudFront invalidation |

## Destroy Order

Reverse of deploy — tear down CloudFront first, then S3, then bootstrap.

### 1. CloudFront (destroy first — depends on S3)

```bash
terraform -chdir=cloudfront init -backend-config=backend/dev.conf
terraform -chdir=cloudfront destroy -var-file=../env/dev.tfvars
```

### 2. S3 Bucket

```bash
terraform -chdir=s3 init -backend-config=backend/dev.conf
terraform -chdir=s3 destroy -var-file=../env/dev.tfvars
```

### 3. Bootstrap (optional — only if decommissioning entirely)

```bash
# GitHub OIDC
aws cloudformation delete-stack --stack-name github-oidc
aws cloudformation wait stack-delete-complete --stack-name github-oidc

# State bucket — empty it first, then delete
aws s3 rm s3://my-terraform-state-bucket --recursive
aws cloudformation delete-stack --stack-name terraform-state-bucket
aws cloudformation wait stack-delete-complete --stack-name terraform-state-bucket
```

> **Warning:** Destroying the state bucket deletes all Terraform state files. Only do this when fully decommissioning the project. If DeletionPolicy is set to `Retain`, you'll need to delete the bucket manually after the stack is removed.

## Security Features

- S3 bucket encryption (AES256)
- S3 versioning enabled
- CloudFront OAC (Origin Access Control) — bucket stays private
- TLS 1.2 minimum on CloudFront
- GitHub OIDC — no long-lived AWS credentials
- Terraform state locking via S3 object lock
