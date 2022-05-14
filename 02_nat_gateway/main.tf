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

# Allocate a ($$$ paid $$$) EIP for the NAT gateway
resource "aws_eip" "nat" {
  count = length(data.terraform_remote_state.vpc.outputs.public_subnet_cidr_blocks)

  vpc = true
  tags = {
    Name        = "v6LabNATGatewayIP"
    Environment = "v6Lab"
  }
}

# Create a ($$$ paid $$$) NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  count = length(data.terraform_remote_state.vpc.outputs.public_subnet_cidr_blocks)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = data.terraform_remote_state.vpc.outputs.public_subnets[count.index].id
  tags = {
    Name        = "v6LabNATGateway"
    Environment = "v6Lab"
  }
}

# Add default IPv4 route to private routing table
# Use the ($$$ paid $$$) NAT gateway instance
resource "aws_route" "private_default_gw" {
  count = length(data.terraform_remote_state.vpc.outputs.private_subnet_cidr_blocks)

  route_table_id         = data.terraform_remote_state.vpc.outputs.private_route_tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway[count.index].id
}

# It might look weird, but yes, NAT gateway accepts this IPv6 route
# It acts as an inter-protocol translator, translating from
# IPv6 to IPv4
resource "aws_route" "private_nat64_default_gw" {
  count = length(data.terraform_remote_state.vpc.outputs.private_subnet_cidr_blocks)

  route_table_id              = data.terraform_remote_state.vpc.outputs.private_route_tables[count.index].id
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = aws_nat_gateway.nat_gateway[count.index].id
}
