provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile_name}"
}

# Create our lab VPC
resource "aws_vpc" "default" {
  cidr_block           = var.cidr_block
  assign_generated_ipv6_cidr_block = true
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "v6LabVPC"
    Environment = "v6Lab"
  }
}

# Create an Internet gateway for IPv4 and IPv6 public subnets
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name        = "v6LabInetGW"
    Environment = "v6Lab"
  }
}

# Create an Egress-only gateway for IPv6 private subnets
resource "aws_egress_only_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name        = "v6LabEgressOnlyGW"
    Environment = "v6Lab"
  }
}

# Create a private routing table
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id = aws_vpc.default.id
  tags = {
    Name        = "v6LabPrivateRouteTable"
    Environment = "v6Lab"
  }
}

# Add a default IPv6 route to the private routing table
# Use the Egress-only internet gateway (free of charge)
resource "aws_route" "private6" {
  count = length(var.private_subnet_cidr6_indexes)

  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.default.id
}

# Create a public routing table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name        = "v6LabPublicRouteTable"
    Environment = "v6Lab"
  }
}

# Add a default IPv4 route to the public routing table
# Use the Internet gateway (free of charge)
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Add a default IPv6 route to the public routing table
# Use the Internet gateway (free of charge)
resource "aws_route" "public6" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.default.id
}

# Create a dual-stacked (supports IPv4+IPv6) private subnet
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id            = aws_vpc.default.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  ipv6_cidr_block   = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, var.private_subnet_cidr6_indexes[count.index])
  assign_ipv6_address_on_creation = true
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name        = "v6LabPrivateDualStackSubnet"
    Environment = "v6Lab"
  }
}

# Create an IPv6-only private subnet
resource "aws_subnet" "private6only" {
  count = length(var.private6only_subnet_cidr6_indexes)

  vpc_id            = aws_vpc.default.id
  ipv6_native       = true
  enable_dns64      = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch = false
  private_dns_hostname_type_on_launch = "resource-name"
  assign_ipv6_address_on_creation = true
  ipv6_cidr_block   = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, var.private6only_subnet_cidr6_indexes[count.index])
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name        = "v6LabPrivateIPv6OnlySubnet"
    Environment = "v6Lab"
  }
}

# Create a dual-stacked (supports IPv4+IPv6) public subnet
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  ipv6_cidr_block         = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, var.public_subnet_cidr6_indexes[count.index])
  assign_ipv6_address_on_creation = true
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name        = "v6LabPublicDualStackSubnet"
    Environment = "v6Lab"
  }
}

# Create an IPv6-only public subnet
resource "aws_subnet" "public6only" {
  count = length(var.public6only_subnet_cidr6_indexes)

  vpc_id                  = aws_vpc.default.id
  ipv6_native             = true
  enable_dns64            = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch = false
  private_dns_hostname_type_on_launch = "resource-name"
  ipv6_cidr_block         = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, var.public6only_subnet_cidr6_indexes[count.index])
  assign_ipv6_address_on_creation = true
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name        = "v6LabPublicIPv6OnlySubnet"
    Environment = "v6Lab"
  }
}

# Map our private routing table to the private subnets
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private6only" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.private6only[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Map our public routing table to the public subnets
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public6only" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public6only[count.index].id
  route_table_id = aws_route_table.public.id
}

### Split into 02_nat_gateway and/or 02_nat_instance

# Allocate a ($$$ paid $$$) EIP for the NAT gateway
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)

  vpc = true
  tags = {
    Name        = "v6LabNATGatewayIP"
    Environment = "v6Lab"
  }
}

# Create a ($$$ paid $$$) NAT gateway
resource "aws_nat_gateway" "default" {
  depends_on = [aws_internet_gateway.default]

  count = length(var.public_subnet_cidr_blocks)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name        = "v6LabNATGateway"
    Environment = "v6Lab"
  }
}

# Add default IPv4 route to private routing table
# Use the ($$$ paid $$$) NAT gateway instance
resource "aws_route" "private" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default[count.index].id
}

resource "aws_route" "private_nat64" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "64:ff9b::/96"
  nat_gateway_id              = aws_nat_gateway.default[count.index].id
}
