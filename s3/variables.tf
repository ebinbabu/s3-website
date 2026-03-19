variable "region" {
  description = "AWS region"
  default     = "ap-south-1"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  type        = string
}

variable "index_document" {
  description = "Index document for the website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for the website"
  type        = string
  default     = "error.html"
}

variable "index_html_path" {
  description = "Path to the index HTML file"
  type        = string
}

variable "error_html_path" {
  description = "Path to the error HTML file"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
