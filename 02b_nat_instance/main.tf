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

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
resource "aws_security_group" "nat64_sg" {
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description      = "SSH from anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ICMPv4 from anywhere"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ICMPv6 from anywhere"
    from_port        = -1
    to_port          = -1
    protocol         = "icmpv6"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "All traffic from within the VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = data.terraform_remote_state.vpc.outputs.ipv4_cidr_blocks
    ipv6_cidr_blocks = data.terraform_remote_state.vpc.outputs.ipv6_cidr_blocks
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "v6LabNAT64SG"
    Environment = "v6Lab"

  }
}
resource "aws_network_interface" "eni_v6LabNAT64Instance" {
  subnet_id         = data.terraform_remote_state.vpc.outputs.public_subnets[0].id
  security_groups   = [aws_security_group.nat64_sg.id]
  # ipv6_prefix_count = 1
  # $ echo "ibase=16; C0011001"|bc
  # 3221295105
  # as in: COOL JOOL (the NAT64 software)
  ipv6_addresses    = [cidrhost(data.terraform_remote_state.vpc.outputs.public_subnets[0].ipv6_cidr_block, 3221295105)]
  source_dest_check = false

  tags = {
    Name        = "eni_v6LabNAT64Instance"
    Environment = "v6Lab"
  }
}

resource "aws_instance" "v6LabNAT64Instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.ssh_key_name

  network_interface {
    network_interface_id = aws_network_interface.eni_v6LabNAT64Instance.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name        = "v6LabNAT64Instance"
    Environment = "v6Lab"
  }
  # user data that get executed on every node start
  user_data = "${file("install_jool.userdata")}"
}


# Add default IPv4 route to private routing table
resource "aws_route" "private_default_gw" {
  count = length(data.terraform_remote_state.vpc.outputs.private_subnet_cidr_blocks)

  route_table_id         = data.terraform_remote_state.vpc.outputs.private_route_tables[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.eni_v6LabNAT64Instance.id
}

# It might look weird, but yes, our NAT instance accepts this IPv6 route
# It acts as an inter-protocol translator, translating from
# IPv6 to IPv4. We need to add routes to both IPv6-only subnet routing tables.
resource "aws_route" "private_nat64_default_gw" {
  count = length(data.terraform_remote_state.vpc.outputs.private_subnet_cidr_blocks)

  route_table_id              = data.terraform_remote_state.vpc.outputs.private_route_tables[count.index].id
  destination_ipv6_cidr_block = "64:ff9b::/96"
  network_interface_id        = aws_network_interface.eni_v6LabNAT64Instance.id
}

resource "aws_route" "public_nat64_default_gw" {
  # If we had more than 1 public IPv6-only subnets...
  # count = length(data.terraform_remote_state.vpc.outputs.public_subnet_cidr_blocks)
  # route_table_id              = data.terraform_remote_state.vpc.outputs.public_route_tables[count.index].id
  # nat_gateway_id              = aws_nat_gateway.nat_gateway[count.index].id
  count                       = 1
  route_table_id              = data.terraform_remote_state.vpc.outputs.public_route_tables.id
  destination_ipv6_cidr_block = "64:ff9b::/96"
  network_interface_id        = aws_network_interface.eni_v6LabNAT64Instance.id
}

