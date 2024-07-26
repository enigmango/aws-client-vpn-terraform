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

variable "create_test_instance" {
  type        = bool
  description = "Set to `true` to create a test instance in the spoke VPC"
  default     = true
}

variable "bypass_nfw" {
  type        = bool
  description = "Set to `true` if you only want to bypass the NFW to test connectivity. Additionally, you can rename or comment out nfw.tf to avoid creating the NFW if you're just testing basic routing."
  default     = false
}