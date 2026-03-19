data "terraform_remote_state" "s3" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "s3/${var.env}/terraform.tfstate"
    region = var.region
  }
}

locals {
  s3_bucket_name                 = data.terraform_remote_state.s3.outputs.bucket_id
  s3_bucket_arn                  = data.terraform_remote_state.s3.outputs.bucket_arn
  s3_bucket_regional_domain_name = data.terraform_remote_state.s3.outputs.bucket_regional_domain_name
  s3_content_hash                = data.terraform_remote_state.s3.outputs.content_hash
}
