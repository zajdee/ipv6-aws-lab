output "dualstack_ipv4_public" {
  value = aws_instance.v6LabEC2DualStack.public_ip
}

output "dualstack_ipv4_private" {
  value = aws_instance.v6LabEC2DualStack.private_ip
}

output "dualstack_ipv6" {
  value = aws_instance.v6LabEC2DualStack.ipv6_addresses
}

output "public_ipv6only_ipv6" {
  value = aws_instance.v6LabPublicEC2IPv6Only.ipv6_addresses
}

output "private_ipv6only_ipv6" {
  value = aws_instance.v6LabPrivateEC2IPv6Only.ipv6_addresses
}