# ------------------------------
# cloud provider
# ------------------------------
provider "aws" {
  region      = "${var.region}"
}
# ------------------------------
# VPC 
# ------------------------------
resource "aws_vpc" "narvar_vpc" {
  cidr_block       = "${var.vpc_cidr_block}"
  instance_tenancy = "default"

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-vpc"
    Billing     = "${var.tag_billing}"
    Developer   = "${var.tag_developer}"
  }
}
# ------------------------------
# public subnets
# ------------------------------
resource "aws_subnet" "public_az1" {
  vpc_id            = "${aws_vpc.narvar_vpc.id}"
  cidr_block        = "${var.public_subnet_cidr_az1}"
  availability_zone = "us-east-1a"

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-public-us-east-1a"
    Developer   = "${var.tag_developer}"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id            = "${aws_vpc.narvar_vpc.id}"
  cidr_block        = "${var.public_subnet_cidr_az2}"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-public-us-east-1b"
    Developer   = "${var.tag_developer}"
  }
}

resource "aws_subnet" "public_az3" {
  vpc_id            = "${aws_vpc.narvar_vpc.id}"
  cidr_block        = "${var.public_subnet_cidr_az3}"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = "true"

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-public-us-east-1c"
    Developer   = "${var.tag_developer}"
  }
}
# ------------------------------
# private subnets
# ------------------------------
resource "aws_subnet" "private_az1" {
  vpc_id            = "${aws_vpc.narvar_vpc.id}"
  cidr_block        = "${var.private_subnet_cidr_az1}"
  availability_zone = "us-east-1a"

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-private-us-east-1a"
    Developer   = "${var.tag_developer}"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = "${aws_vpc.narvar_vpc.id}"
  cidr_block        = "${var.private_subnet_cidr_az2}"
  availability_zone = "us-east-1b"

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-private-us-east-1b"
    Developer   = "${var.tag_developer}"
  }
}

resource "aws_subnet" "private_az3" {
  vpc_id            = "${aws_vpc.narvar_vpc.id}"
  cidr_block        = "${var.private_subnet_cidr_az3}"
  availability_zone = "us-east-1c"

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-private-us-east-1c"
    Developer   = "${var.tag_developer}"
  }
}
# ------------------------------
# internet gateway
# ------------------------------
resource "aws_internet_gateway" "vpc_gw" {
  vpc_id = "${aws_vpc.narvar_vpc.id}"

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-IGW"
  }
}
# ------------------------------
# elastic IP (Required for NAT gateway)
# ------------------------------
resource "aws_eip" "nat_eip" {
  vpc           = true
  //depends_on    = ["aws_nat_gateway.vpc_nat_gw"]
  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-EIP"
  }
}
# ------------------------------
# NAT gateway
# ------------------------------
resource "aws_nat_gateway" "vpc_nat_gw" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.public_az2.id}"
  depends_on = ["aws_internet_gateway.vpc_gw"]

  tags {
    Name        = "${var.tag_environment}-${var.tag_name}-NGW"
  }
}

# ------------------------------
# route table to public
# ------------------------------
resource "aws_route_table" "public_route_table" {
  vpc_id                 = "${aws_vpc.narvar_vpc.id}"
  //route_table_id         = "${aws_vpc.narvar_vpc.main_route_table_id}"

  tags {
    Name = "${var.tag_environment}-${var.tag_name}-public-RT"
  }
}

# route to internet for public
resource "aws_route" "public_route" {
  route_table_id         = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.vpc_gw.id}"
}
# ------------------------------
# route table to private
# ------------------------------
resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.narvar_vpc.id}"

  tags {
    Name = "${var.tag_environment}-${var.tag_name}-private-RT"
  }
}

# route to internet for private
resource "aws_route" "private_route" {
	route_table_id  = "${aws_route_table.private_route_table.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.vpc_nat_gw.id}"
}
# ------------------------------
# route table association
# ------------------------------
# associating public subnets to route table :
resource "aws_route_table_association" "public_subnet_az1" {
  subnet_id = "${aws_subnet.public_az1.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "public_subnet_az2" {
  subnet_id = "${aws_subnet.public_az2.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "public_subnet_az3" {
  subnet_id = "${aws_subnet.public_az3.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

# associating private subnets to route table :
resource "aws_route_table_association" "private_subnet_az1" {
  subnet_id = "${aws_subnet.private_az1.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_route_table_association" "private_subnet_az2" {
  subnet_id = "${aws_subnet.private_az2.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_route_table_association" "private_subnet_az3" {
  subnet_id = "${aws_subnet.private_az3.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}