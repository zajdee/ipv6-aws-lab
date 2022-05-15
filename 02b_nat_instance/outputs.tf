output "dualstack_ipv4_public" {
  value = aws_instance.v6LabNAT64Instance.public_ip
}

output "dualstack_ipv4_private" {
  value = aws_instance.v6LabNAT64Instance.private_ip
}

output "dualstack_ipv6" {
  value = aws_instance.v6LabNAT64Instance.ipv6_addresses
}
