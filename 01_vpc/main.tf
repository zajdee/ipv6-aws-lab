provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile_name}"
}

data "aws_region" "current" {}

# Create our lab VPC
resource "aws_vpc" "default_vpc" {
  cidr_block                       = var.cidr_block
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true

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
    Name = format(
      "v6LabPrivateRouteTable-%s%s",
      var.region,
      var.availability_zones[count.index])
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
  count = length(var.public_subnet_cidr_blocks)

  vpc_id = aws_vpc.default_vpc.id

  tags = {
    Name = format(
      "v6LabPublicRouteTable-%s%s",
      var.region,
      var.availability_zones[count.index])
    Environment = "v6Lab"
  }
}

# Add a default IPv4 route to the public routing table
# Use the Internet gateway (free of charge)
resource "aws_route" "public_default_route" {
  count = length(var.public_subnet_cidr_blocks)

  route_table_id         = aws_route_table.public_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Add a default IPv6 route to the public routing table
# Use the Internet gateway (free of charge)
resource "aws_route" "public6_default_route6" {
  count = length(var.public_subnet_cidr6_indexes)

  route_table_id              = aws_route_table.public_route_table[count.index].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw.id
}

# Create a dual-stacked (supports IPv4+IPv6) private subnet
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id            = aws_vpc.default_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = format(
    "%s%s",
    var.region,
    var.availability_zones[count.index])

  ipv6_cidr_block = cidrsubnet(
    aws_vpc.default_vpc.ipv6_cidr_block,
    8,
    parseint(var.private_subnet_cidr6_indexes[count.index], 16)
  )

  assign_ipv6_address_on_creation = true

  tags = {
    Name        = format("v6LabPrivateDualStackSubnet-%s%s", var.region, var.availability_zones[count.index])
    Environment = "v6Lab"
  }
}

# Create an IPv6-only private subnet
resource "aws_subnet" "private6only_subnet" {
  count = length(var.private6only_subnet_cidr6_indexes)

  vpc_id            = aws_vpc.default_vpc.id
  ipv6_native       = true
  enable_dns64      = true
  availability_zone = format(
    "%s%s",
    var.region,
    var.availability_zones[count.index])

  ipv6_cidr_block = cidrsubnet(
    aws_vpc.default_vpc.ipv6_cidr_block,
    8,
    parseint(var.private6only_subnet_cidr6_indexes[count.index], 16)
  )

  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch    = false
  private_dns_hostname_type_on_launch            = "resource-name"
  assign_ipv6_address_on_creation                = true

  tags = {
    Name        = format("v6LabPrivateIPv6OnlySubnet-%s%s", var.region, var.availability_zones[count.index])
    Environment = "v6Lab"
  }
}

# Create a dual-stacked (supports IPv4+IPv6) public subnet
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                          = aws_vpc.default_vpc.id
  cidr_block                      = var.public_subnet_cidr_blocks[count.index]
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true

  availability_zone = format(
    "%s%s",
    var.region,
    var.availability_zones[count.index])

  ipv6_cidr_block = cidrsubnet(
    aws_vpc.default_vpc.ipv6_cidr_block,
    8,
    parseint(var.public_subnet_cidr6_indexes[count.index], 16)
  )

  tags = {
    Name        = format("v6LabPublicDualStackSubnet-%s%s", var.region, var.availability_zones[count.index])
    Environment = "v6Lab"
  }
}

# Create an IPv6-only public subnet
resource "aws_subnet" "public6only_subnet" {
  count = length(var.public6only_subnet_cidr6_indexes)

  vpc_id                  = aws_vpc.default_vpc.id
  ipv6_native             = true
  enable_dns64            = true
  map_public_ip_on_launch = false

  availability_zone = format(
    "%s%s",
    var.region,
    var.availability_zones[count.index])

  ipv6_cidr_block = cidrsubnet(
    aws_vpc.default_vpc.ipv6_cidr_block,
    8,
    parseint(var.public6only_subnet_cidr6_indexes[count.index], 16)
  )

  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch    = false
  private_dns_hostname_type_on_launch            = "resource-name"
  assign_ipv6_address_on_creation                = true

  tags = {
    Name        = format("v6LabPublicIPv6OnlySubnet-%s%s", var.region, var.availability_zones[count.index])
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
  route_table_id = aws_route_table.public_route_table[count.index].id
}

resource "aws_route_table_association" "public6only_rta" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public6only_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table[count.index].id
}

# Finally, deploy an S3 Gateway endpoint to all routing tables
# Gateway endpoints are free of charge and the traffic routed via these
# is also free of charge
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.default_vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "private_rta_s3" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id  = aws_route_table.private_route_table[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "public_rta_s3" {
  count = length(var.public_subnet_cidr_blocks)

  route_table_id  = aws_route_table.public_route_table[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# NAT gateway is created separately
