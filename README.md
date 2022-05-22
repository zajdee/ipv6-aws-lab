# IPv6 @ AWS lab

This is a simple lab to set-up an IPv6-enabled environment in AWS. It is in no way production grade code, however it does ease the initial set-up of a lab so that you don't have to click around.

## QR code link to this repository
![Link to this repository](qrlink.png "Link to this repository")

## Prerequisities

You need the following tools to try this lab:

- Git client to clone this repository
- AWS CLI ([official packages](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), [macOS Homebrew formula](https://formulae.brew.sh/formula/awscli))
- Terraform ([oficial binaries](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- A decent text editor or IDE to edit the files (if necessary)
- AWS account that can create API keys and browse the AWS console
- SSH client to access the created EC2 instances and poke around

It is also good to be on a network with IPv6 connectivity. If you don't have it, some examples may fail to deploy or you may find it hard to test the result.

IMPORTANT NOTE: If you are testing on Windows, you might be on your own. WSL on Windows does not support IPv6 even if you are connected to an IPv6-enabled network.

# Setting up

1. Install git client, AWS CLI and terraform binary
2. Create a SSH key (if you don't have one) and add it to your SSH agent ([Github guide for macOS, Linux and Windows](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent))
3. Log in to the AWS console. Pick a region where you will be trying the examples (or use the `eu-west-2` (London) default)
4. **If you don't have your SSH keys in AWS yet:** Add your SSH key to AWS:
   1. Open [AWS console](https://console.aws.amazon.com/console/home) and log-in
   2. Search for EC2 and go to the EC2 management section
   3. In the upper right corner, pick a region of your choice; write down the Region code (you will need it later). See the [AWS list of all regions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).
   4. In the EC2 management, in the menu on the left side, click Key Pairs.
   5. In the right upper corner then click `Actions->Import key pair`
   6. Give the key pair a decent name (you will need it in your configs later) and paste the **public key** part of your SSH key. Then click `Import key pair`
5. **If you don't have AWS access keys yet:** Generate your API keys and configure your computer
   1. In the AWS console, in the top right corner click on your user name. A pop-up menu appears. Click on Security credentials. This will get you to the Identity and Access Management (IAM)
   2. In the `Your Security Credentials` section, click `Access keys (access key ID and secret access key)` and then `Create New Access Key`. Keep the credentials safe! These can be misused by malicious actor. It is recommended to delete the access keys after you conclude with this lab, to avoid misuse
   3. There's a [comprehensive access key management guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) in the AWS docs.

Now that you have your access keys ready, add them to the `~/.aws/credentials` file, like this (include your region of choice):
```
[aws-ipv6-lab]
aws_access_key_id=DEADBEEF
aws_secret_access_key=WVNvQ3VyaW91cz8K
region=eu-west-2
```

Note that the profile is called `aws-ipv6-lab`; if you don't want to modify the examples, please use this profile name.

## A small IPv6 theory

IPv6 is a second internet protocol, next to IPv4. It is not directly compatible with IPv4, so it's kind of expected that you will run both at the same time.

AWS does not enable IPv6 in your environment by default. That means: VPCs, subnets, services are mostly configured to be IPv4-only, and you need to flip the switches in the right locations.

The IPv6 addresses look like `2001:db8:dead:beef:bad:cafe:bad:babe`.
- Note that the number format is hexadecimal, there are 8 groups of numbers, each number group can range from `0` to `ffff`.
- Leading zeros in each group should not be written (but might be, if that's what you wish).
- Two or more consecutive zero groups are usually shortened to a `::` (e.g. `2001:db8:dead:beef:0:0:0:1` becomes `2001:db8:dead:beef::1`)
- If there are two distinct zero groups, the longer one becomes shortened (e.g. `2001:db8:0:0:0:1:0:0` becomes `2001:db8::1:0:0`)
- IPv6 as well as IPv4 uses network masks. In IPv4, network masks go from `/0` (the whole Internet) to `/32` (single address). In IPv6, it's `/0` (the whole Internet) to `/128` (single address)
- In IPv4, a typical home subnet network mask is `/24` while in AWS this may not be enough, so we may go up to a `16` (~65530 hosts) per subnet. In IPv6, the subnet for an access network at home as well as for the AWS subnets is `/64` (`2^64` hosts in theory)

### Tasks
The lab is split into several tasks.

- [01_vpc](01_vpc/README.md): Create a VPC with IPv6+IPv4 (dual-stack) and IPv6-only subnets
- [02a_nat_gateway](02a_nat_gateway/README.md): Create a NAT gateway [$$$]
- [02b_nat_instance](02b_nat_instance/README.md): Create a NAT EC2 instance (cheaper, we will also use it as a jump host)
- [03_ec2](03_ec2/README.md): Create a few EC2 instances in public and private subnets, dual-stacked and IPv6-only ones
- [04_ec2_docker](04_ec2_docker/README.md): Create an EC2 instance with Docker and test some IPv6-enabled containers
- [05_nginx_alb](05_nginx_alb/README.md): Create an EC2 instance with IPv6-only NginX and dual-stacked ALB and NLB to see how can you run IPv6-only service behind dual-stacked balancers
- [06_s3](06_s3/README.md): Create a S3 bucket and test accessing it using IPv6
- [07_rds](07_rds/README.md): Create a dual-stacked RDS database instance

When all the above is created, you can poke around the console and EC2 instances to see how IPv6 works.

If you don't have IPv6 connectivity on your network, you can use the NAT instance as a bastion (jump) host - it's dual-stacked, so you can connect to it via IPv4 and connect to the IPv6 resources from there.

### Costs

The lab is scheduled for 2 hours, the total costs of al the tasks is in dollars at maximum (not dozens or hundreds).

### Destruction

Please remember that most of the resources created in this lab are paid ones. Remember to destroy whatever you have created by running `terraform destroy` in the following lab tasks sequence:
- `07_rds`
- `06_s3`
- `05_nginx_nlb_alb`
- `04_ec2_docker`
- `03_ec2`
- `02b_nat_instance`
- `02a_nat_gateway`
- `01_vpc`

A convenient one-liner might be:

```
for lab in 07_rds 06_s3 05_nginx_nlb_alb 04_ec2_docker 03_ec2 02b_nat_instance 01_vpc; do cd $lab; terraform destroy; cd ..; done
```

**We are not responsible for extra costs incurred by you not destroying your lab resources.**
