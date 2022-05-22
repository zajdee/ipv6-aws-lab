# AWS LAB: `02a_nat_gateway`

This deployment creates a NAT EC2 instance. It conflicts with `02a_nat_gateway`.
The NAT instance supports IPv4 to IPv4 NAT (NAT44) as well as IPv6-to-IPv4 NAT (NAT64).
The instance is placed in the first public subnet so that it has public IPv4 as well as global IPv6 address.

The NAT instance is required for all other lab tasks, so please deploy it and keep it deployed.

# Resources built by this lab

- A NAT EC2 instance with [Jool](http://jool.mx/) (NAT64) installed
  - Also creates an ENI in the first public dual-stack subnet
  - Also creates a security group to let traffic in
- Routing table entries:
    - IPv4 default gateway in all the private routing tables
    - IPv6 route towards `64:ff9b::/96` (the NAT64 default prefix) in all public and private routing tables

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

# View Terraform output

Run the following to get the NAT instance addresses (will be useful later).

```
$ terraform output
dualstack_ipv4_private = "100.96.14.154"
dualstack_ipv4_public = "192.0.2.171"
dualstack_ipv6 = tolist([
  "2001:db8:c0fe:fe00::c001:1001",
])
```


# How to destroy

Please note that all other components depend on this one. Destroy this one as the very last one.

```
terraform destroy
```