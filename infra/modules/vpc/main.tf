# ==============================
# DEFAULT VPC
# ==============================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {}

# ==============================
# PRIVATE SUBNETS
# (Manually assign safe CIDR blocks)
# ==============================

resource "aws_subnet" "private" {
  count      = 2
  vpc_id     = data.aws_vpc.default.id
  cidr_block = count.index == 0 ? "172.31.240.0/24" : "172.31.241.0/24"

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-private-${count.index}"
  }
}

# ==============================
# NAT GATEWAY
# (Placed in existing public subnet)
# ==============================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(data.aws_subnets.public.ids, 0)

  tags = {
    Name = "${var.name}-nat"
  }
}

# ==============================
# PRIVATE ROUTE TABLE
# ==============================

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "${var.name}-private-rt"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}