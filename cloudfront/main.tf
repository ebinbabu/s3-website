module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "6.4.0"

  comment             = "CDN for ${local.s3_bucket_name} static website"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  default_root_object = var.index_document

  origin = {
    s3_website = {
      domain_name               = local.s3_bucket_regional_domain_name
      origin_access_control_key = "s3"
    }
  }

  origin_access_control = {
    s3 = {
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_name      = "Managed-CachingOptimized"
  }

  custom_error_response = [
    {
      error_code         = 403
      response_code      = 404
      response_page_path = "/${var.error_document}"
    },
    {
      error_code         = 404
      response_code      = 404
      response_page_path = "/${var.error_document}"
    }
  ]

  viewer_certificate = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2025"
  }

  tags = var.tags
}

# Bucket policy for CloudFront OAC
resource "aws_s3_bucket_policy" "cloudfront_oac" {
  bucket = local.s3_bucket_name
  policy = data.aws_iam_policy_document.cloudfront_oac.json
}

data "aws_iam_policy_document" "cloudfront_oac" {
  statement {
    sid       = "AllowCloudFrontOAC"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${local.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront.cloudfront_distribution_arn]
    }
  }
}

# Invalidate CloudFront cache when S3 content or distribution changes
resource "terraform_data" "cloudfront_invalidation" {
  triggers_replace = "${local.s3_content_hash}-${module.cloudfront.cloudfront_distribution_etag}"

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${module.cloudfront.cloudfront_distribution_id} --paths '/*'"
  }
}
