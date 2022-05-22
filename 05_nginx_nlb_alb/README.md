# AWS LAB: `05_nginx_nlb_alb`

This deployment creates a NginX webserver together with an Application Load Balancer (ALB) and a Network Load Balancer.
The balancers are dual-stacked, however use IPv6-only to talk to the backend (nginx server).

This is an example of how to configure IPv6 with the NLB and ALB, including the Proxy protocol between NginX and ALB/NLB.

**THIS MODULE REQUIRES THE NAT INSTANCE ([02b_nat_instance](../02b_nat_instance/README.md)) TO BE DEPLOYED.**

# Resources built by this lab

- NginX EC2 instance in a public dual-stacked subnet
  - With a security group and the respective ENI
- Network Load Balancer (NLB)
  - Dual-stacked hostname
  - IPv6-only backend
  - NLB listener, target and attachment
- Application Load Balancer (ALB)
  - Dual-stacked hostname
  - IPv6-only backend
  - ALB listener, target and attachment

IMPORTANT: The NAT instance is used as a bastion (jump) host for the NginX configuration on the node.

# How to deploy

You MUST set the SSH key in `terraform.tfvars`. You MAY also change the region from the default `eu-west-2` (London), create `terraform.tfvars` and add the `region=` line to it (this example sets the region to `eu-west-3` (Paris)):

```
$ cat terraform.tfvars
ssh_key_name="rzajic"
region="eu-west-3"
```

You can also add other variables to the config file.

The deployment itself:

```
terraform init
terraform plan
terraform apply
```

# View Terraform output and verify it works

Run

```
$  terraform output
v6LabWebALB_hostname = "tf-lb-20220522194641738900000006-2062295913.eu-west-2.elb.amazonaws.com"
v6LabWebEC2_ipv6 = tolist([
  "2001:db8:c0fe:fe20::ebb",
])
v6LabWebEC2_private_ipv4 = "100.96.16.253"
v6LabWebNLB_hostname = "tf-lb-20220522194639647800000003-f8db592fbc2a8280.elb.eu-west-2.amazonaws.com"
```

Now run `cURL` against the two NLB/ALB hostnames:

```
$ curl -6 -s -I http://tf-lb-20220522194639647800000003-f8db592fbc2a8280.elb.eu-west-2.amazonaws.com/
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sun, 22 May 2022 20:02:31 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Sun, 22 May 2022 19:47:17 GMT
Connection: keep-alive
ETag: "628a9345-264"
Accept-Ranges: bytes
```

```
$ curl -6 -s -I http://tf-lb-20220522194641738900000006-2062295913.eu-west-2.elb.amazonaws.com/
HTTP/1.1 200 OK
Date: Sun, 22 May 2022 20:02:34 GMT
Content-Type: text/html
Content-Length: 612
Connection: keep-alive
Server: nginx/1.18.0 (Ubuntu)
Last-Modified: Sun, 22 May 2022 19:47:17 GMT
ETag: "628a9345-264"
Accept-Ranges: bytes
```

# How to destroy

Please note that all other components depend on this one. Destroy this one as the very last one.

```
terraform destroy
```

