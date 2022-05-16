output "v6LabWebEC2_ipv6" {
  value = aws_instance.v6LabWebEC2.ipv6_addresses
}

output "v6LabWebEC2_private_ipv4" {
  value = aws_instance.v6LabWebEC2.private_ip
}

output "v6LabWebNLB_hostname" {
  value = aws_lb.v6LabNLB.dns_name
}

output "v6LabWebALB_hostname" {
  value = aws_lb.v6LabALB.dns_name
}
