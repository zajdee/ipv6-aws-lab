output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.v6LabPSQL.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.v6LabPSQL.port
  sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.v6LabPSQL.username
  sensitive   = true
}

output "bastion_ipv6_address" {
  description = "Bastion (jump) host IPv6 address"
  value = data.terraform_remote_state.nat_instance.outputs.dualstack_ipv6[0]
}

output "bastion_ipv4_address" {
  description = "Bastion (jump) host IPv4 address"
  value = data.terraform_remote_state.nat_instance.outputs.dualstack_ipv4_public
}