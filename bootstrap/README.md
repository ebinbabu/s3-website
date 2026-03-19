# Bootstrap

CloudFormation templates for foundational resources that Terraform depends on. These are deployed once and rarely changed.

## Templates

### terraform-state-bucket.yaml

S3 bucket for Terraform state with:
- Object lock enabled (native S3 state locking)
- Versioning enabled
- AES256 encryption
- Public access blocked
- Lifecycle rule to expire noncurrent versions (default: 90 days)
- DeletionPolicy configurable (Retain recommended for production)

```bash
aws cloudformation deploy \
  --template-file bootstrap/terraform-state-bucket.yaml \
  --stack-name terraform-state-bucket \
  --parameter-overrides BucketName=my-terraform-state-bucket
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BucketName` | — | Name of the S3 bucket (required) |
| `NoncurrentVersionExpirationDays` | 90 | Days to retain old state file versions |

### github-oidc.yaml

GitHub Actions OIDC identity provider and IAM role for CI/CD. Follows least privilege — scoped to specific state and website buckets.

```bash
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

| Parameter | Description |
|-----------|-------------|
| `GitHubOrg` | GitHub organization or username |
| `GitHubRepo` | GitHub repository name |
| `StateBucketName` | Terraform state S3 bucket name |
| `WebsiteBucketName` | Static website S3 bucket name |

After deploying, get the role ARN and add it as `AWS_ROLE_ARN` secret in GitHub:

```bash
aws cloudformation describe-stacks --stack-name github-oidc \
  --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' --output text
```
