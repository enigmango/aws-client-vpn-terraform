variable "region" {
  type        = string
  description = "AWS region where this will be deployed"
  default     = "us-east-2"
}

variable "tags" {
  type        = map(string)
  description = "Common tags to use on all resources"
  default = {
    Terraform   = "true"
    Environment = "dev"
    Repo        = "tf-sb-baseline"
    Name        = "example"
  }
}