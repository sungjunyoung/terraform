resource "aws_vpc" "sungjunyoung" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = {
    Name = var.vpc_name
  }
}

#---
# VPC Subnets
#---
resource "aws_subnet" "private" {
  for_each = {for idx, cidr_block in var.private_subnets : cidr_block => idx}

  vpc_id                  = aws_vpc.sungjunyoung.id
  cidr_block              = each.key
  map_public_ip_on_launch = false
  availability_zone       = var.azs[each.value%3]
  tags                    = merge(
    {for eks_cluster_name in [var.eks_cluster_name] : "kubernetes.io/cluster/${eks_cluster_name}" => "shared"},
    { Name = "${var.vpc_name}-private-${var.azs[each.value%3]}"},
    { "kubernetes.io/role/internal-elb" = "1" }
  )
}

resource "aws_subnet" "public" {
  for_each = {for idx, cidr_block in var.public_subnets : cidr_block => idx}

  vpc_id                  = aws_vpc.sungjunyoung.id
  cidr_block              = each.key
  map_public_ip_on_launch = true
  availability_zone       = var.azs[each.value%3]
  tags                    = merge(
    {for eks_cluster_name in [var.eks_cluster_name] : "kubernetes.io/cluster/${eks_cluster_name}" => "shared"},
    { Name = "${var.vpc_name}-public-${var.azs[each.value%3]}"},
    { "kubernetes.io/role/elb" = "1" }
  )
}

#---
# Internet Gateway
#---
resource "aws_internet_gateway" "sungjunyoung" {
  vpc_id = aws_vpc.sungjunyoung.id
  tags   = merge(
    {for eks_cluster_name in [var.eks_cluster_name] : "kubernetes.io/cluster/${eks_cluster_name}" => "shared"},
    { Name = var.vpc_name }
  )
}

#---
# NAT Gateway
#---
resource "aws_eip" "sungjunyoung" {
  vpc        = true
  depends_on = [aws_internet_gateway.sungjunyoung]
  tags       = {
    Name = var.vpc_name
  }
}

resource "aws_nat_gateway" "sungjunyoung" {
  allocation_id = aws_eip.sungjunyoung.id
  subnet_id     = values(aws_subnet.public)[0].id
  depends_on    = [aws_internet_gateway.sungjunyoung]
  tags          = {
    Name = var.vpc_name
  }
}

#---
# Routing Tables
#---
# Private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.sungjunyoung.id
  tags   = {
    Name = "${var.vpc_name}-private"
  }
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.sungjunyoung.id
}

resource "aws_route_table_association" "private" {
  for_each = {for idx, subnet in aws_subnet.private : idx => subnet.id}

  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}

# Public
resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.sungjunyoung.default_route_table_id
  tags                   = {
    Name = "${var.vpc_name}-public"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_vpc.sungjunyoung.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sungjunyoung.id
}

resource "aws_route_table_association" "public" {
  for_each = {for idx, subnet in aws_subnet.public : idx => subnet.id}

  subnet_id      = each.value
  route_table_id = aws_vpc.sungjunyoung.main_route_table_id
}

#---
# Network ACL
#---
resource "aws_default_network_acl" "public" {
  default_network_acl_id = aws_vpc.sungjunyoung.default_network_acl_id
  subnet_ids             = concat(
    values(aws_subnet.private)[*].id,
    values(aws_subnet.public)[*].id,
  )

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = aws_vpc.sungjunyoung.cidr_block
  }

  ingress {
    rule_no    = 200
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = aws_vpc.sungjunyoung.cidr_block
  }

  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = var.vpc_name
  }
}