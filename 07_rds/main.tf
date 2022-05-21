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
# to the database, which will be hidden in a private subnet
data "terraform_remote_state" "nat_instance" {
  backend = "local"

  config = {
    path = "../02b_nat_instance/terraform.tfstate"
  }
}

resource "aws_security_group" "v6LabPSQLSG" {
  description = "Allow PSQL inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description      = "PostgreSQL from anywhere (DANGEROUS)"
    from_port        = 5432
    to_port          = 5432
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
    Name        = "v6LabPSQLSG"
    Environment = "v6Lab"
  }
}

resource "aws_db_subnet_group" "v6LabPSQLSubnet" {
  name       = "v6labpsqlsubnet"
  subnet_ids = [
  for subnet in data.terraform_remote_state.vpc.outputs.private_subnets : subnet.id
  ]

  tags = {
    Name        = "v6LabPSQLSubnet"
    Environment = "v6Lab"
  }
}

resource "aws_db_instance" "v6LabPSQL" {
  identifier             = "v6labpsql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  # If you get an error like "Cannot find version 13.X for postgres",
  # run aws rds describe-db-engine-versions --default-only --engine postgres
  # to get currently available versions.
  engine_version         = "13.6"
  username               = "v6lab"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.v6LabPSQLSubnet.name
  vpc_security_group_ids = [aws_security_group.v6LabPSQLSG.id]
  parameter_group_name   = aws_db_parameter_group.v6LabPSQLParamGroup.name
  publicly_accessible    = false
  skip_final_snapshot    = true
  apply_immediately      = true

  tags = {
    Name        = "v6LabPSQL"
    Environment = "v6Lab"
  }
}

resource "aws_db_parameter_group" "v6LabPSQLParamGroup" {
  name   = "v6labpsqlparamgroup"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = {
    Name        = "v6LabPSQLParamGroup"
    Environment = "v6Lab"
  }
}

# Now you need to change the subnet type to "DUAL"
# aws rds modify-db-instance --region your-region \
#   --db-instance-identifier v6labpsql --network-type DUAL --apply-immediately
#
# You can check if AWS changed the argument by running
# aws rds --region your-region describe-db-instances
#
# Wait for the change to complete
#
# Get the new instance hostname
# terraform output rds_hostname
#
# Then log in to the NAT instance as user `ubuntu`. Get its address using
# terraform output
#
# On the NAT instance, install postgresql-client
# sudo apt-get install postgresql-client
#
# Then log in to postgres using
# psql -6 -h <rds_hostname> -p 5432 -U v6lab  postgres

# More details are in the guide on https://learn.hashicorp.com/tutorials/terraform/aws-rds?in=terraform/aws
