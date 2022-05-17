provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile_name}"
}

# Import the VPC resources
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../01_vpc/terraform.tfstate"
  }
}

resource "aws_s3_bucket" "v6LabS3Bucket" {
  # Note we intentionally don't set the bucket name (bucket = "...")
  # Terraform will create a random ID, and that's good enough for us

  tags = {
    Name        = "v6LabS3Bucket"
    Environment = "v6Lab"
  }
}

resource "aws_s3_bucket_acl" "v6LabS3BucketACL" {
  bucket = aws_s3_bucket.v6LabS3Bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "v6LabS3BucketPolicy" {
  bucket = aws_s3_bucket.v6LabS3Bucket.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = [
          aws_s3_bucket.v6LabS3Bucket.arn,
          "${aws_s3_bucket.v6LabS3Bucket.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_object" "object" {
  bucket  = aws_s3_bucket.v6LabS3Bucket.id
  key     = var.hello_ipv6_key
  acl     = "public-read"
  content = var.hello_ipv6_value
  etag    = md5(var.hello_ipv6_value)
}

# Try as:
# $ curl -6 https://terraform-20220517203506979200000001.s3.dualstack.eu-west-2.amazonaws.com/hello_ipv6.txt
# Hello, IPv6!
