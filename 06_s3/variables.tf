variable "region" {
  default     = "eu-west-2"
  type        = string
  description = "Region of the VPC"
}

variable "aws_profile_name" {
  default     = "aws-ipv6-lab"
  type        = string
  description = "Name of the profile section in your ~/.aws/credentials file"
}

variable "hello_ipv6_key" {
  default     = "hello_ipv6.txt"
  type        = string
  description = "Key (path) of the S3 object"
}

variable "hello_ipv6_value" {
  default     = "Welcome to the IPv6 world!\n"
  type        = string
  description = "Value of the S3 object"
}