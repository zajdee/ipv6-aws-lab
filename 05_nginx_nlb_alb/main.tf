provider "aws" {
  region  = var.region
  profile = var.aws_profile_name
}

# Import the VPC resources
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../01_vpc/terraform.tfstate"
  }
}

# Import the NAT instance resources
# We will use the NAT instance as a bastion (jump) host to connect
# to the webserver, which will be hidden in a private subnet
data "terraform_remote_state" "nat_instance" {
  backend = "local"

  config = {
    path = "../02b_nat_instance/terraform.tfstate"
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
resource "aws_security_group" "v6LabWebALBSG" {
  description = "Allow server inbound traffic to the ALB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 81
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "v6LabWebALBSG"
    Environment = "v6Lab"
  }
}

resource "aws_security_group" "v6LabWebSG" {
  description = "Allow server inbound traffic"
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
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 81
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from anywhere"
    from_port        = 443
    to_port          = 443
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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "v6LabWebSG"
    Environment = "v6Lab"
  }
}

# EC2 in an IPv6-only private subnet
resource "aws_network_interface" "eni_v6LabWebEC2" {
  # Once Target groups with IPv6 targets are supported by AWS Terraform provider, let's go IPv6-only!
  # subnet_id       = data.terraform_remote_state.vpc.outputs.private6only_subnets[0].id

  subnet_id       = data.terraform_remote_state.vpc.outputs.private_subnets[0].id
  security_groups = [aws_security_group.v6LabWebSG.id]
  # $ echo "ibase=16; EBB" | bc (as in "web")
  # 3771
  # ipv6_addresses  = [cidrhost(data.terraform_remote_state.vpc.outputs.private6only_subnets[0].ipv6_cidr_block, 3771)]
  ipv6_addresses  = [cidrhost(data.terraform_remote_state.vpc.outputs.private_subnets[0].ipv6_cidr_block, 3771)]
  # Comment this out once the instance moves to an IPv6-only subnet
  private_ips     = [cidrhost(data.terraform_remote_state.vpc.outputs.private_subnets[0].cidr_block, 253)]

  tags = {
    Name        = "eni_v6LabWebEC2"
    Environment = "v6Lab"
  }
}

# NLB: A TCP-based load balancer. Dual-stacked, with IPv6-only backend server
resource "aws_lb" "v6LabNLB" {
  internal           = false
  load_balancer_type = "network"
  ip_address_type    = "dualstack"

  subnets = [
  for subnet in data.terraform_remote_state.vpc.outputs.public_subnets : subnet.id
  ]

  tags = {
    Name        = "v6LabNLB"
    Environment = "v6Lab"
  }
}
resource "aws_lb_listener" "v6LabNLBListener" {
  load_balancer_arn = aws_lb.v6LabNLB.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.v6LabNLBTarget.arn
  }

  tags = {
    Name        = "v6LabNLBListener"
    Environment = "v6Lab"
  }
}
resource "aws_lb_target_group" "v6LabNLBTarget" {
  port              = 80
  protocol          = "TCP"
  proxy_protocol_v2 = true
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id

  # NLB with IPv6 targets requires us to point to an IPv6 address, hence target_type = "ip"
  # The AWS provider does not (yet) support the IPv6 targets. :(
  # See https://github.com/hashicorp/terraform-provider-aws/issues/23386
  # and https://github.com/hashicorp/terraform-provider-aws/pull/21973 for more details
  # For now we will set-up an IPv4-only connection to the backend
  target_type = "ip"
  # ip_address_type = "ipv6"

  health_check {
    protocol = "TCP"
    port     = 80
  }

  tags = {
    Name        = "v6LabNLBTarget"
    Environment = "v6Lab"
  }
}
resource "aws_lb_target_group_attachment" "v6LabNLBAttachment" {
  target_group_arn = aws_lb_target_group.v6LabNLBTarget.arn
  port             = 80

  # This is commented out until the IPv6 backends are supported by the AWS Terraform provider
  # target_id = aws_instance.v6LabWebEC2.ipv6_addresses[0]
  target_id = aws_instance.v6LabWebEC2.private_ip
}

# ALB: A HTTP(S)-based load balancer. Dual-stacked, with IPv6-only backend server
resource "aws_lb" "v6LabALB" {
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "dualstack"
  security_groups    = [aws_security_group.v6LabWebALBSG.id]

  subnets = [
  for subnet in data.terraform_remote_state.vpc.outputs.public_subnets : subnet.id
  ]

  tags = {
    Name        = "v6LabALB"
    Environment = "v6Lab"
  }
}
resource "aws_lb_listener" "v6LabALBListener" {
  load_balancer_arn = aws_lb.v6LabALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.v6LabALBTarget.arn
  }

  tags = {
    Name        = "v6LabNLBListener"
    Environment = "v6Lab"
  }
}
resource "aws_lb_target_group" "v6LabALBTarget" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id

  # ALB with IPv6 targets requires us to point to an IPv6 address, hence target_type = "ip"
  # The AWS provider does not (yet) support the IPv6 targets. :(
  # See https://github.com/hashicorp/terraform-provider-aws/issues/23386
  # and https://github.com/hashicorp/terraform-provider-aws/pull/21973 for more details
  # For now we will set-up an IPv4-only connection to the backend
  target_type = "ip"
  # ip_address_type = "ipv6"

  health_check {
    protocol = "HTTP"
    port     = 81
  }

  tags = {
    Name        = "v6LabALBTarget"
    Environment = "v6Lab"
  }
}
resource "aws_lb_target_group_attachment" "v6LabALBAttachment" {
  target_group_arn = aws_lb_target_group.v6LabALBTarget.arn
  port             = 81

  # This is commented out until the IPv6 backends are supported by the AWS Terraform provider
  # target_id = aws_instance.v6LabWebEC2.ipv6_addresses[0]
  target_id = aws_instance.v6LabWebEC2.private_ip
}

# Web server instance
resource "aws_instance" "v6LabWebEC2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.ssh_key_name

  network_interface {
    network_interface_id = aws_network_interface.eni_v6LabWebEC2.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "standard"
  }

  # This requires a working SSH agent with your key installed; if your SSH client is unable to forward
  # the authentication, the connection from the bastion host to the nginx EC2 instance
  # in the private subnet will not work and the "terraform apply" job will fail.
  #
  # We use the NAT instance created in 02b_nat_instance as a bastion host (jump server)
  connection {
    # The default username for our AMI
    user         = "ubuntu"
    host         = self.ipv6_addresses[0]
    # Only one bastion_host can be specified, therefore pick one based on your environment and comment the other one out
    # If you have a working IPv6 connectivity from your computer, uncomment this line
    bastion_host = data.terraform_remote_state.nat_instance.outputs.dualstack_ipv6[0]
    # If you don't have a working IPv6 connectivity, uncomment this line
    # bastion_host = data.terraform_remote_state.nat_instance.outputs.dualstack_ipv4_public
    bastion_user = "ubuntu"
    # The connection will use the local SSH agent for authentication.
  }

  # TBD: Deploy the nginx_config to the node
  # Remember, these commands are executed as `ubuntu`, therefore need sudo
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo systemctl stop nginx",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/nginx_config"
    destination = "/tmp/nginx-default"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/nginx-default /etc/nginx/sites-available/default",
      "sudo systemctl restart nginx",
    ]
  }

  tags = {
    Name        = "v6LabWebEC2"
    Environment = "v6Lab"
  }
}
