provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile_name}"
}

# Create our lab VPC
resource "aws_vpc" "default_vpc" {
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
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default_vpc.id
  tags = {
    Name        = "v6LabInetGW"
    Environment = "v6Lab"
  }
}

# Create an Egress-only gateway for IPv6 private subnets
resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = aws_vpc.default_vpc.id
  tags = {
    Name        = "v6LabEgressOnlyGW"
    Environment = "v6Lab"
  }
}

# Create a private routing table
resource "aws_route_table" "private_route_table" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id = aws_vpc.default_vpc.id
  tags = {
    Name        = "v6LabPrivateRouteTable"
    Environment = "v6Lab"
  }
}

# Add a default IPv6 route to the private routing table
# Use the Egress-only internet gateway (free of charge)
resource "aws_route" "private6_default_route6" {
  count = length(var.private_subnet_cidr6_indexes)

  route_table_id              = aws_route_table.private_route_table[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw.id
}

# Create a public routing table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.default_vpc.id
  tags = {
    Name        = "v6LabPublicRouteTable"
    Environment = "v6Lab"
  }
}

# Add a default IPv4 route to the public routing table
# Use the Internet gateway (free of charge)
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Add a default IPv6 route to the public routing table
# Use the Internet gateway (free of charge)
resource "aws_route" "public6_default_route6" {
  route_table_id              = aws_route_table.public_route_table.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw.id
}

# Create a dual-stacked (supports IPv4+IPv6) private subnet
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id            = aws_vpc.default_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  ipv6_cidr_block   = cidrsubnet(aws_vpc.default_vpc.ipv6_cidr_block, 8, var.private_subnet_cidr6_indexes[count.index])
  assign_ipv6_address_on_creation = true
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name        = "v6LabPrivateDualStackSubnet"
    Environment = "v6Lab"
  }
}

# Create an IPv6-only private subnet
resource "aws_subnet" "private6only_subnet" {
  count = length(var.private6only_subnet_cidr6_indexes)

  vpc_id            = aws_vpc.default_vpc.id
  ipv6_native       = true
  enable_dns64      = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch = false
  private_dns_hostname_type_on_launch = "resource-name"
  assign_ipv6_address_on_creation = true
  ipv6_cidr_block   = cidrsubnet(aws_vpc.default_vpc.ipv6_cidr_block, 8, var.private6only_subnet_cidr6_indexes[count.index])
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name        = "v6LabPrivateIPv6OnlySubnet"
    Environment = "v6Lab"
  }
}

# Create a dual-stacked (supports IPv4+IPv6) public subnet
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.default_vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  ipv6_cidr_block         = cidrsubnet(aws_vpc.default_vpc.ipv6_cidr_block, 8, var.public_subnet_cidr6_indexes[count.index])
  assign_ipv6_address_on_creation = true
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name        = "v6LabPublicDualStackSubnet"
    Environment = "v6Lab"
  }
}

# Create an IPv6-only public subnet
resource "aws_subnet" "public6only_subnet" {
  count = length(var.public6only_subnet_cidr6_indexes)

  vpc_id                  = aws_vpc.default_vpc.id
  ipv6_native             = true
  enable_dns64            = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch = false
  private_dns_hostname_type_on_launch = "resource-name"
  ipv6_cidr_block         = cidrsubnet(aws_vpc.default_vpc.ipv6_cidr_block, 8, var.public6only_subnet_cidr6_indexes[count.index])
  assign_ipv6_address_on_creation = true
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name        = "v6LabPublicIPv6OnlySubnet"
    Environment = "v6Lab"
  }
}

# Map our private routing table to the private subnets
resource "aws_route_table_association" "private_rta" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

resource "aws_route_table_association" "private6only_rta" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.private6only_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# Map our public routing table to the public subnets
resource "aws_route_table_association" "public_rta" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public6only_rta" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public6only_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# NAT gateway is created separately
