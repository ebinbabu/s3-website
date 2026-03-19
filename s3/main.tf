module "s3_static_website" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket        = var.bucket_name
  force_destroy = true

  website = {
    index_document = var.index_document
    error_document = var.error_document
  }

  # Encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Versioning
  versioning = {
    enabled = true
  }

  tags = var.tags
}

resource "aws_s3_object" "index" {
  bucket       = module.s3_static_website.s3_bucket_id
  key          = var.index_document
  source       = var.index_html_path
  content_type = "text/html"
  etag         = filemd5(var.index_html_path)
}

resource "aws_s3_object" "error" {
  bucket       = module.s3_static_website.s3_bucket_id
  key          = var.error_document
  source       = var.error_html_path
  content_type = "text/html"
  etag         = filemd5(var.error_html_path)
}
