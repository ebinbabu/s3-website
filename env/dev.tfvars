region         = "ap-south-1"
bucket_name    = "my-static-website-ebi1232-dev"
index_document = "index.html"
error_document = "error.html"
state_bucket   = "my-terraform-state-bucket-ebin"
env            = "dev"

index_html_path = "../content/dev/index.html"
error_html_path = "../content/dev/error.html"

tags = {
  Environment = "dev"
  Project     = "static-website"
}
