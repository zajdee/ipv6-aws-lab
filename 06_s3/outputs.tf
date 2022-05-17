output "v6LabS3Bucket_ipv4only_fqdn" {
  value = aws_s3_bucket.v6LabS3Bucket.bucket_regional_domain_name
}

output "v6LabS3Bucket_dualstack_fqdn" {
  value = format("%s.s3.dualstack.%s.amazonaws.com",
    aws_s3_bucket.v6LabS3Bucket.id,
    aws_s3_bucket.v6LabS3Bucket.region
  )
}