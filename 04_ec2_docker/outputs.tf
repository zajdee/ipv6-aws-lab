output "v6LabDockerEC2_public_ipv4" {
  value = aws_instance.v6LabDockerEC2.public_ip
}

output "v6LabDockerEC2_private_ipv4" {
  value = aws_instance.v6LabDockerEC2.private_ip
}

output "v6LabDockerEC2_ipv6" {
  value = data.template_file.init.vars.system_ipv6_address
}

output "v6LabDockerEC2_ipv6_prefixes" {
  value = aws_network_interface.eni_v6LabDockerEC2.ipv6_prefixes
}

output "v6LabDockerEC2_docker_ipv6_prefix" {
  value = data.template_file.init.vars.docker_prefix
}