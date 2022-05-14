output "private_route_tables" {
  value = aws_route_table.private_route_table
}

output "public_subnets" {
  value = aws_subnet.public_subnet
}
output "public_subnet_cidr_blocks" {
  value = var.public_subnet_cidr_blocks
}

output "private_subnet_cidr_blocks" {
  value = var.private_subnet_cidr_blocks
}
