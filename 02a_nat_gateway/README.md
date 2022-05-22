# AWS LAB: `02a_nat_gateway`

This deployment creates managed NAT gateway(s). It conflicts with `02b_nat_instance`, so it's here more like an example of how to do so.
The NAT gateway supports IPv4 to IPv4 NAT (NAT44) as well as IPv6-to-IPv4 NAT (NAT64).

# Resources built by this lab

- A NAT gateway (be careful, it's costly)
- Routing table entries:
  - IPv4 default gateway in all the private routing tables
  - IPv6 route towards `64:ff9b::/96` (the NAT64 default prefix) in all public and private routing tables

# How to deploy

If you wish to change the region from the default `eu-west-2` (London), create `terraform.tfvars` and add the following line to it (this example sets the region to `eu-west-3` (Paris)):

```
$ cat terraform.tfvars
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

Run

```
terraform output
```

# How to destroy

Please note that all other components depend on this one. Destroy this one as the very last one.

```
terraform destroy
```

