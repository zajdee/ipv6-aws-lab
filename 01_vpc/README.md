# AWS LAB: `01_vpc`

This example creates a dual-stacked VPC with dual-stacked and IPv6-only subnets.

Short VPC IPv6 addressing theory:

- If you enable IPv6 in a VPC, each VPC gets its initial /56 IPv6 prefix
- You can have up to 256 /64 subnet prefixes per each /56 VPC prefix
- You can have up to 5 /56 prefixes per VPC, totalling for up to 1280 /64 prefixes per VPC
- Each VPC subnet can be assigned zero or one IPv6 /64 prefix; this size cannot be changed
- EC2 ENIs in each VPC subnets can be assigned individual IPv6 addresses (using DHCPv6) AND larger /80 prefixes
  - There are 65534 **available** IPv6 prefixes in a VPC subnet available for subdelegation to EC2s
  - The first and last **subnet** (e.g. `2001:db8:c0fe:fe00:0::/80` and `2001:db8:c0fe:fe00:ffff::/80`) are reserved for AWS and cannot be assigned to an ENI
- It is up to the EC2/ENI combination how many IPv6 resources (addresses and prefixes count together) can you use
- Even the smallest EC2 ENIs (e.g. ENI attached to a `t3.nano`) can have up to 2 IPv6 resources assigned, e.g. one IPv6 address and one /80 prefix
- The /80 prefix can be split into smaller prefixes, e.g. each /80 can be split up to 65536 /96 prefixes (each holding the whole IPv4 internet!) for container networks on the EC2s
- You currently cannot assign an IPv6 address AND an IPv6 prefix to an instance at a time; this is a limitation of the EC2 API. You can assign an address on creation and assign a /80 prefix to the same ENI later.
- You can create "native" IPv6 subnets: these are subnets where there's no IPv4 available

# An example address plan, as built by this lab

| Purpose | Prefix | Can be split into | Starting addr or prefix | Ending address or prefix |
|---|---|---|---|---|
| VPC prefix | 2001:db8:c0fe:fe00::/56 | 256 /64 prefixes | 2001:db8:c0fe:fe00::/64 | 2001:db8:c0fe:feff::/56 |
| Subnet prefix | 2001:db8:c0fe:fe00::/64 | 65534 /80 prefixes | 2001:db8:c0fe:fe00:1::/80 | 2001:db8:c0fe:fe00:1::/80 |

Let's assume we have `2001:db8:c0fe:fe00::/56` as our VPC prefix. Then the following applies. Note that we often assign specific IPv6 addresses to the EC2 instances, but you can also let AWS assign random addresses for you.

How subnets are addressed:

```
 2001:db8:c0fe:fe00:: -- Primary VPC prefix
+                yy:: -- Subnet bytes [00..ff]
+                    /64
```

Address plan:

```
2001:db8:c0fe:fe00::/56 -- Primary VPC prefix
|
+-+- 2001:db8:c0fe:fe00::/64 -- Public dual-stack subnet, AZ1
| |  +- 2001:db8:c0fe:fe00::c001:1001 -- IPv6 address of the NAT instance
| |  +- 2001:db8:c0fe:fe00::dead:beef -- IPv6 address of the EC2 public subnet dual-stacked EC2 instance
| |  |
| |  +- 2001:db8:c0fe:fe00:4000::/80 -- Delegated prefix for the Docker lab
| |  |  +- 2001:db8:c0fe:fe00:4000:0::1/128 -- IPv6 address of the Docker lab EC2 instance
| |  |  +- 2001:db8:c0fe:fe00:4000:1::/96 -- IPv6 address of the Docker lab EC2 container network
| |  |  +- 2001:db8:c0fe:fe00:4000:1::/96 -- Reserved prefix within the Docker instance
| |  |  +- (...)
| |  |  +- 2001:db8:c0fe:fe00:4000:ffff::/96 -- Reserved prefix within the Docker instance
| |
| +- 2001:db8:c0fe:fe01::/64 -- Public dual-stack subnet, AZ2
| +- 2001:db8:c0fe:fe02::/64 -- Public dual-stack subnet, AZ3
| +- 2001:db8:c0fe:fe03::/64 -- Reserve for public dual-stack subnet #4
| +- (...)
| +- 2001:db8:c0fe:fe0f::/64 -- Reserve for public dual-stack subnet #15
|
+-+- 2001:db8:c0fe:fe10::/64 -- Public IPv6-only subnet, AZ1
| |  +- 2001:db8:c0fe:fe10::face:b00c -- IPv6 address of the EC2 public subnet IPv6-only EC2 instance
| +- 2001:db8:c0fe:fe11::/64 -- Public IPv6-only subnet, AZ2
| +- 2001:db8:c0fe:fe12::/64 -- Public IPv6-only subnet, AZ3
| +- 2001:db8:c0fe:fe13::/64 -- Reserve for public IPv6-only subnet #4
| +- (...)
| +- 2001:db8:c0fe:fe1f::/64 -- Reserve for public IPv6-only subnet #15
|
+-+- 2001:db8:c0fe:fe20::/64 -- Private dual-stack subnet, AZ1
| |  +- 2001:db8:c0fe:fe20::ebb -- IPv6 address of the EC2 private subnet dual-stacked webserver instance
| |  +- 2001:db8:c0fe:fe20::c01d:cafe -- IPv6 address of the EC2 private subnet dual-stacked EC2 instance
| +- 2001:db8:c0fe:fe21::/64 -- Private dual-stack subnet, AZ2
| +- 2001:db8:c0fe:fe22::/64 -- Private dual-stack subnet, AZ3
| +- 2001:db8:c0fe:fe23::/64 -- Reserve for private dual-stack subnet #4
| +- (...)
| +- 2001:db8:c0fe:fe2f::/64 -- Reserve for private dual-stack subnet #15
|
+-+- 2001:db8:c0fe:fe30::/64 -- Private IPv6-only subnet, AZ1
| |  +- 2001:db8:c0fe:fe30::bad:cafe -- IPv6 address of the EC2 private subnet IPv6-only EC2 instance
| +- 2001:db8:c0fe:fe31::/64 -- Private IPv6-only subnet, AZ2
| +- 2001:db8:c0fe:fe32::/64 -- Private IPv6-only subnet, AZ3
| +- 2001:db8:c0fe:fe33::/64 -- Reserve for private IPv6-only subnet #4
| +- (...)
| +- 2001:db8:c0fe:fe3f::/64 -- Reserve for private IPv6-only subnet #15
|
+-+- 2001:db8:c0fe:fe40::/64 -- Reserved for future growth
  +- (...)
  +- 2001:db8:c0fe:feff::/64 -- Reserved for future growth
```

Looks great, doesn't it?
Well, that's why you will want an IP address management (IPAM) tool to manage this for you. :-)


# Aggregating subnets

You might have noticed that we only modify fourth group when creating a subnet.

We take `2001:db8:c0fe:fexx::` and use `30`, `31` and `32` for the private IPv6-only subnets, finally applying a /64 network mask, resulting in:
- `2001:db8:c0fe:fe30::/64`
- `2001:db8:c0fe:fe31::/64`
- `2001:db8:c0fe:fe32::/64`

This approach is natural with IPv6, so is the hierarchical addressing.

With this plan, you can aggregate all private IPv6-only subnets, including the reserve for future growth (`2001:db8:c0fe:fe33::/64`..`2001:db8:c0fe:fe3f::/64`) into a single ACL line, `2001:db8:c0fe:fe30::/60`.

# Resources built by this lab

The following resources are created:

- an IPv6-enabled VPC
- an IPv4+IPv6 IGW (Internet gateway), which allows for outgoing and incoming connections
- an IPv6 EIGW (Egress-only internet gateway), which only allows outgoing connections
- subnets in each availability zone (assuming 3 availability zones):
  - Dual-stacked (IPv4+IPv6) public subnet
  - IPv6-only public subnet
  - Dual-stacked (IPv4+IPv6) private subnet
  - IPv6-only private subnet
- routing tables in each availability zone:
  - one private subnet routing table with IPv6 EIGW default gateway and without IPv4 default gateway
  - one public subnet routing table with IGW as both IPv4 and IPv6 default gateway
- S3 gateway endpoints in each routing table (these only seem to support IPv4)

Note that with this configuration, resources in your VPC private subnets will not have a route to the IPv4 internet, but they will have a route to the IPv6 internet.

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

# How to destroy

Please note that all other components depend on this one. Destroy this one as the very last one.

```
terraform destroy
```
