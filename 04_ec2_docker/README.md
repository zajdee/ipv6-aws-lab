# AWS LAB: `04_ec2_docker`

This deployment creates managed NAT gateway(s). It conflicts with `02b_nat_instance`, so it's here more like an example of how to do so.
The NAT gateway supports IPv4 to IPv4 NAT (NAT44) as well as IPv6-to-IPv4 NAT (NAT64).

# Resources built by this lab

- A NAT EC2 instance with [Jool](http://jool.mx/) (NAT64) installed
  - Also creates an ENI in the first public dual-stack subnet
  - Also creates a security group to let traffic in
  - Due to the AWS API limitations, only a `/80` subnet is assigned, not a single address (see below for details)
  - Special `cloud-init` template is used to always reconfigure `/etc/docker/daemon.json` with the up to date delegated `/80` prefix on instance start

# IP addressing

A `/80` prefix is delegated to the instance, e.g. `2001:db8:c0fe:fe00:4000::/80`. This prefix is then split as follows:

- `2001:db8:c0fe:fe00:4000::1` (or `2001:db8:c0fe:fe00:4000:0::1`) - the IPv6 address of the instance, configured by the cloud-init script
- `2001:db8:c0fe:fe00:4000:1::/96` a sub-prefix of the `/80`, used as the default docker network

# Test IPv6 and docker

Get the instance addresses:

```
$ terraform output v6LabDockerEC2_ipv6
"2001:db8:c0fe:fe00:4000::1"
$ terraform output v6LabDockerEC2_public_ipv4
"192.0.2.173"
```

SSH to one of the IPs:

```
$ ssh ubuntu@2001:db8:c0fe:fe00:4000::1

ubuntu@ip-100-96-4-11:~$ sudo docker run -it wbitt/network-multitool:latest /bin/bash
Unable to find image 'wbitt/network-multitool:latest' locally
latest: Pulling from wbitt/network-multitool
59bf1c3509f3: Pull complete
de4aa02b3951: Pull complete
3b1a5a3b831b: Pull complete
bea7f2db9e27: Pull complete
999e38f68670: Pull complete
Digest: sha256:82a5ea955024390d6b438ce22ccc75c98b481bf00e57c13e9a9cc1458eb92652
Status: Downloaded newer image for wbitt/network-multitool:latest
The directory /usr/share/nginx/html is not mounted.
Therefore, over-writing the default index.html file with some useful information:
WBITT Network MultiTool (with NGINX) - 2457d7ed6677 - 172.17.0.2 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
bash-5.1# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
6: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 2001:db8:c0fe:fe00:4000:1:0:2/96 scope global nodad
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:2/64 scope link
       valid_lft forever preferred_lft forever

bash-5.1# mtr -w -c3 -b google.com
Start: 2022-05-22T19:36:53+0000
HOST: 2457d7ed6677                                                          Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 2001:db8:c0fe:fe00:4000:1:0:1 (2001:db8:c0fe:fe00:4000:1:0:1)          0.0%     3    0.1   0.1   0.1   0.1   0.0
  2.|-- 2620:107:4000:2210:8000:0:3438:55 (2620:107:4000:2210:8000:0:3438:55)  0.0%     3    0.6   7.5   0.6  15.4   7.5
  3.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
  4.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
  5.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
  6.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
  7.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
  8.|-- 2a01:578:0:4201:8000:0:6441:821 (2a01:578:0:4201:8000:0:6441:821)      0.0%     3    1.6   6.8   1.6  10.3   4.6
  9.|-- 2a01:578:0:12::5a (2a01:578:0:12::5a)                                  0.0%     3    6.4   3.5   2.0   6.4   2.5
 10.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
 11.|-- 2a01:578:0:12::24 (2a01:578:0:12::24)                                  0.0%     3    1.6   1.6   1.6   1.6   0.0
 12.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
 13.|-- 2a01:578:0:9003::21 (2a01:578:0:9003::21)                              0.0%     3    2.5   2.4   2.0   2.7   0.4
 14.|-- 2a01:578:0:9003::1c (2a01:578:0:9003::1c)                              0.0%     3    2.1   2.5   2.0   3.4   0.8
 15.|-- 2a01:578:0:9003::43 (2a01:578:0:9003::43)                              0.0%     3    2.2   2.1   1.9   2.3   0.2
 16.|-- 2a01:578:0:9003::4 (2a01:578:0:9003::4)                                0.0%     3    2.7   2.4   2.2   2.7   0.3
 17.|-- 2a01:578:0:9003::9 (2a01:578:0:9003::9)                                0.0%     3    2.0   5.1   2.0  11.2   5.3
 18.|-- 2a01:578:0:8000::62 (2a01:578:0:8000::62)                              0.0%     3    1.8   1.8   1.7   2.1   0.2
 19.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
 20.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
 21.|-- ???                                                                   100.0     3    0.0   0.0   0.0   0.0   0.0
 22.|-- 2001:4860:0:1::50a2 (2001:4860:0:1::50a2)                             66.7%     3    2.9   2.9   2.9   2.9   0.0
 23.|-- 2001:4860:0:1::537b (2001:4860:0:1::537b)                              0.0%     3    1.6   1.8   1.5   2.4   0.5
 24.|-- lhr48s28-in-x0e.1e100.net (2a00:1450:4009:821::200e)                   0.0%     3    1.6   1.6   1.5   1.6   0.1
```

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

Run

```
$ terraform output
v6LabDockerEC2_docker_ipv6_prefix = "2001:db8:c0fe:fe00:4000:1::/96"
v6LabDockerEC2_ipv6 = "2001:db8:c0fe:fe00:4000::1"
v6LabDockerEC2_ipv6_prefixes = toset([
  "2001:db8:c0fe:fe00:4000::/80",
])
v6LabDockerEC2_private_ipv4 = "100.96.4.11"
v6LabDockerEC2_public_ipv4 = "192.0.2.173"
```


# How to destroy

Please note that all other components depend on this one. Destroy this one as the very last one.

```
terraform destroy
```

# Next step

You may continue to deploy the [NginX with NLB and ALB](../05_nginx_nlb_alb/README.md).
