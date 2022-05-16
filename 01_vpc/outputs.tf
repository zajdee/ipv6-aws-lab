output "private_route_tables" {
  value = aws_route_table.private_route_table
}

output "public_route_tables" {
  value = aws_route_table.public_route_table
}

output "public_subnets" {
  value = aws_subnet.public_subnet
}

output "public6only_subnets" {
  value = aws_subnet.public6only_subnet
}

output "private_subnets" {
  value = aws_subnet.private_subnet
}

output "private6only_subnets" {
  value = aws_subnet.private6only_subnet
}

output "public_subnet_cidr_blocks" {
  value = var.public_subnet_cidr_blocks
}

output "private_subnet_cidr_blocks" {
  value = var.private_subnet_cidr_blocks
}

output "public6only_subnet_cidr6_indexes" {
  value = var.public6only_subnet_cidr6_indexes
}

output "private6only_subnet_cidr6_indexes" {
  value = var.private6only_subnet_cidr6_indexes
}

output "vpc_id" {
  value = aws_vpc.default_vpc.id
}

output "ipv4_cidr_blocks" {
  value = [aws_vpc.default_vpc.cidr_block]
}

output "ipv6_cidr_blocks" {
  value = [aws_vpc.default_vpc.ipv6_cidr_block]
}

output "region" {
  value = var.region
}

output "availability_zones" {
  value = var.availability_zones
}
