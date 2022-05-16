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

# Expects you to have a key in AWS account->EC2 (https://console.aws.amazon.com/ec2/)->Network & Security->Key Pairs
variable "ssh_key_name" {
  default     = ""
  type        = string
  description = "Name of your SSH key"
}
