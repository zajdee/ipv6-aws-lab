output "v6LabPublicEC2DualStack_public_ipv4" {
  value = aws_instance.v6LabPublicEC2DualStack.public_ip
}

output "v6LabPublicEC2DualStack_private_ipv4" {
  value = aws_instance.v6LabPublicEC2DualStack.private_ip
}

output "v6LabPublicEC2DualStack_ipv6" {
  value = aws_instance.v6LabPublicEC2DualStack.ipv6_addresses
}

output "v6LabPrivateEC2DualStack_private_ipv4" {
  value = aws_instance.v6LabPrivateEC2DualStack.private_ip
}

output "v6LabPrivateEC2DualStack_ipv6" {
  value = aws_instance.v6LabPrivateEC2DualStack.ipv6_addresses
}

output "v6LabPublicEC2IPv6Only_ipv6" {
  value = aws_instance.v6LabPublicEC2IPv6Only.ipv6_addresses
}

output "v6LabPrivateEC2IPv6Only_ipv6" {
  value = aws_instance.v6LabPrivateEC2IPv6Only.ipv6_addresses
}
