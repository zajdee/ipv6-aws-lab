# AWS LAB: `06_s3`

This deployment creates managed NAT gateway(s). It conflicts with `02b_nat_instance`, so it's here more like an example of how to do so.
The NAT gateway supports IPv4 to IPv4 NAT (NAT44) as well as IPv6-to-IPv4 NAT (NAT64).

# Resources built by this lab

- A simple S3 bucket
- A file is placed to the S3 bucket

# How to deploy

You MAY change the region from the default `eu-west-2` (London), create `terraform.tfvars` and add the following line to it (this example sets the region to `eu-west-3` (Paris)):

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
$ terraform output
v6LabS3Bucket_dualstack_fqdn = "terraform-20220522200500520400000001.s3.dualstack.eu-west-2.amazonaws.com"
v6LabS3Bucket_ipv4only_fqdn = "terraform-20220522200500520400000001.s3.eu-west-2.amazonaws.com"
```

Notice the difference in the hostnames. Only the one with `dualstack` in it is available over both IPv4 and IPv6.

```
$ curl -6 https://terraform-20220522200500520400000001.s3.eu-west-2.amazonaws.com/hello_ipv6.txt
curl: (7) Couldn't connect to server
```

```
$ curl -s -6 https://terraform-20220522200500520400000001.s3.dualstack.eu-west-2.amazonaws.com/hello_ipv6.txt
Welcome to the IPv6 world!
```

# How to destroy

Please note that all other components depend on this one. Destroy this one as the very last one.

```
terraform destroy
```

# Next step

You may continue to deploy the [Dual-stacked RDS DB instance](../07_rds/README.md).
