locals {
  octet = "73"
  azs = {
    "${var.region}a" = 0
    "${var.region}b" = 1
  }
}

resource "aws_vpc" "sb" {
  cidr_block = "10.${local.octet}.0.0/16"
  tags = var.tags
}

resource "aws_eip" "nat" {
  for_each = local.azs
  domain = "vpc"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.sb.id
}

resource "aws_nat_gateway" "nat" {
  for_each = local.azs
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags          = var.tags
}

resource "aws_subnet" "public" {
  for_each = local.azs
  vpc_id            = aws_vpc.sb.id
  cidr_block        = "10.${local.octet}.${each.value}.0/24"
  availability_zone = each.key
}

resource "aws_subnet" "private" {
  for_each = local.azs
  vpc_id            = aws_vpc.sb.id
  cidr_block        = "10.${local.octet}.${100+each.value}.0/24"
  availability_zone = each.key
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sb.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = local.azs
  vpc_id = aws_vpc.sb.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
}

resource "aws_route_table_association" "private" {
  for_each = local.azs
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

output "ips" {
  value = values(aws_eip.nat)[*].public_ip
}