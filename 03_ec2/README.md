# AWS LAB: `03_ec2`

This deployment creates several EC2 instances in various subnet combinations (IPv4+IPv6 dual-stack vs. IPv6-only, public vs. private).

# Resources built by this lab

- Several EC2 resources (see table below)
  - Also creates an ENI in the first public dual-stack subnet
  - Also creates a security groups to let traffic in

| Instance name | Subnet type | Has IPv4? | Has IPv6? |
|---|---|---|---|
|`v6LabPublicEC2DualStack` | Dual-stack, public | Yes, public and private | Yes, public
|`v6LabPrivateEC2DualStack` | Dual-stack, private | Yes, public and private | Yes, firewalled
|`v6LabPublicEC2IPv6Only` | IPv6-only, public | None | Yes, public
|`v6LabPrivateEC2IPv6Only` | IPv6-only, private | None | Yes, firewalled

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

Run the following to list IPs of all the instances

```
$ terraform output
v6LabPrivateEC2DualStack_ipv6 = tolist([
"2001:db8:c0fe:fe20::c01d:cafe",
])
v6LabPrivateEC2DualStack_private_ipv4 = "100.96.30.151"

v6LabPrivateEC2IPv6Only_ipv6 = tolist([
"2001:db8:c0fe:fe30::bad:cafe",
])

v6LabPublicEC2DualStack_ipv6 = tolist([
"2001:db8:c0fe:fe00::dead:beef",
])
v6LabPublicEC2DualStack_private_ipv4 = "100.96.10.224"
v6LabPublicEC2DualStack_public_ipv4 = "18.133.182.9"

v6LabPublicEC2IPv6Only_ipv6 = tolist([
"2001:db8:c0fe:fe10::face:b00c",
])
```


# How to destroy

Please note that all other components depend on this one. Destroy this one as the very last one.

```
terraform destroy
```