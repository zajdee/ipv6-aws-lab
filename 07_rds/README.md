# AWS LAB: `07_rds`

This deployment creates a dual-stacked RDS DB instance.

# Resources built by this lab

- AWS RDS DB instance
  - With DB subnet, security group
  - Default DB username is `v6lab`

# How to deploy and test

You MAY change the region from the default `eu-west-2` (London), create `terraform.tfvars` and add the following line to it (this example sets the region to `eu-west-3` (Paris)):

```
$ cat terraform.tfvars
region="eu-west-3"
```

You can also add other variables to the config file.


Before you start the deployment, PLEASE SET YOUR PASSWORD as the environment variable.
The deployment itself:

```
export TF_VAR_db_password="YourRandomPassword"
terraform init
terraform plan
terraform apply
```

Now you need to change the subnet type to "DUAL"

```
$ aws rds modify-db-instance --profile aws-ipv6-lab --region your-region \
   --db-instance-identifier v6labpsql --network-type DUAL --apply-immediately
```

You can check if AWS changed the argument by running

```
aws rds --region your-region describe-db-instances
```

Wait for the change to complete, then get the new instance hostname

```
terraform output rds_hostname
```

Then log in to **the NAT instance** as user `ubuntu`. Get its address using

```
$ terraform output
bastion_ipv4_address = "192.0.2.171"
bastion_ipv6_address = "2001:db8:c0fe:fe00::c001:1001"
rds_hostname = <sensitive>
rds_port = <sensitive>
rds_username = <sensitive>
```

You will also need the RDS database hostname:

```
$ terraform output rds_hostname
"v6labpsql.(...).rds.amazonaws.com"
```

On the NAT instance, install postgresql-client

```
sudo apt-get update
sudo apt-get -y install postgresql-client net-tools
```

Then log in to postgres using this command and YOUR password (set above during deployment).

```
$ psql -h v6labpsql.(...).rds.amazonaws.com -p 5432 -U v6lab postgres
Password for user v6lab:
psql (12.10 (Ubuntu 12.10-0ubuntu0.20.04.1), server 13.6)
WARNING: psql major version 12, server major version 13.
         Some psql features might not work.
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=> \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | v6lab    | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 rdsadmin  | rdsadmin | UTF8     | en_US.UTF-8 | en_US.UTF-8 | rdsadmin=CTc/rdsadmin+
           |          |          |             |             | rdstopmgr=Tc/rdsadmin
 template0 | rdsadmin | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/rdsadmin          +
           |          |          |             |             | rdsadmin=CTc/rdsadmin
 template1 | v6lab    | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/v6lab             +
           |          |          |             |             | v6lab=CTc/v6lab
(4 rows)

postgres=>
```

If you open another SSH session to the NAT instance and run `netstat` to verify that the connection runs over IPv6.

```
netstat -ltnp
```

(More details on the Terraform code for RDS DB are in the [official guide](https://learn.hashicorp.com/tutorials/terraform/aws-rds?in=terraform/aws).)

# How to destroy

Please note that all other components depend on this one. Destroy this one as the very last one.

```
terraform destroy
```

# Next step

Now you have created all the resources. You can poke around and investigate the configuration of IPv6 in the VPC and EC2 instances, or for example deploy a dual-stacked Cloudfront distribution. When you are done, return to the [root README](../README.md#destruction) and destroy the resources.