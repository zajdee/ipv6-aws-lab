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
  default     = ["100.96.0.0/20"]
  type        = list
  description = "List of public subnet CIDR blocks"
}

variable "public_subnet_cidr6_indexes" {
  default     = [0]
  type        = list
  description = "List of public subnet CIDR blocks"
}

variable "public6only_subnet_cidr6_indexes" {
  default     = [1]
  type        = list
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks" {
  default     = ["100.96.16.0/20"]
  type        = list
  description = "List of private subnet CIDR blocks"
}

variable "private_subnet_cidr6_indexes" {
  default     = [2]
  type        = list
  description = "List of public subnet CIDR blocks"
}

variable "private6only_subnet_cidr6_indexes" {
  default     = [3]
  type        = list
  description = "List of public subnet CIDR blocks"
}

variable "availability_zones" {
  default     = ["eu-west-2a"]
  type        = list
  description = "List of availability zones"
}
