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

variable "cidr_block" {
  default     = "100.96.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_blocks" {
  default     = ["100.96.0.0/20", "100.96.64.0/20", "100.96.128.0/20"]
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

# Terraform doesn't understand hexadecimal numbers; however IPv6 network planning
# in decimal is tough, so let's use parseint() and parse those hexadecimal strings
variable "public_subnet_cidr6_indexes" {
  default     = ["00", "01", "02"]
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

variable "public6only_subnet_cidr6_indexes" {
  default     = ["10", "11", "12"]
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks" {
  default     = ["100.96.16.0/20", "100.96.80.0/20", "100.96.144.0/20"]
  type        = list(string)
  description = "List of private subnet CIDR blocks"
}

variable "private_subnet_cidr6_indexes" {
  default     = ["20", "21", "22"]
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

variable "private6only_subnet_cidr6_indexes" {
  default     = ["30", "31", "32"]
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

variable "availability_zones" {
  default     = ["a", "b", "c"]
  type        = list(string)
  description = "List of availability zones"
}
