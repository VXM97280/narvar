# ------------------------------------
# test-narvar-asg auto scalling group security group
# -------------------------------------
resource "aws_security_group" "test_narvar_default_sg" {
  name        = "${var.tag_environment}-${var.tag_name}-default"
  description = "SG for narvar ec2"
  vpc_id      = "${aws_vpc.narvar_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups  = ["${aws_security_group.test_narvar_nat_sg.id}"]
  }

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["10.128.0.0/16", "10.2.0.0/16"]
#   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags {
    Name            = "test-narvar-sg"
    Environment     = "${var.tag_environment}"
    Developer       = "${var.tag_developer}"
    Terraform       = "true"
  }
}

# --------------------------------------------
# test-narvar-asg load balancer security group
# --------------------------------------------
resource "aws_security_group" "test_narvar_elb_sg" {
  name        = "${var.tag_environment}-${var.tag_name}-elb-sg"
  description = "SG for ELB"
  vpc_id      = "${aws_vpc.narvar_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0" ]
    ipv6_cidr_blocks     = ["::/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0" ]
    ipv6_cidr_blocks     = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags {
    Name            = "${var.tag_environment}-${var.tag_name}-elb-sg"
    Environment     = "${var.tag_environment}"
    Developer       = "${var.tag_developer}"
    Terraform       = "true"
  }
}

# -------------------------------------------------
# test-narvar-asg auto scaling group security group
# -------------------------------------------------
resource "aws_security_group" "test_narvar_asg_sg" {
  name        = "${var.tag_environment}-${var.tag_name}-asg-sg"
  description = "SG for ASG"
  vpc_id      = "${aws_vpc.narvar_vpc.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.test_narvar_elb_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name            = "${var.tag_environment}-${var.tag_name}-asg-sg"
    Environment     = "${var.tag_environment}"
    Developer       = "${var.tag_developer}"
    Terraform       = "true"
  }
}
# ------------------------------------
# test-narvar-nat security group
# -------------------------------------
resource "aws_security_group" "test_narvar_nat_sg" {
  name        = "${var.tag_environment}-${var.tag_name}-nat-sg"
  description = "SG for narvar nat instance"
  vpc_id      = "${aws_vpc.narvar_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags {
    Name            = "test-narvar-nat-sg"
    Environment     = "${var.tag_environment}"
    Developer       = "${var.tag_developer}"
    Terraform       = "true"
  }
}
# -------------------------------------------------
# ec2 policy
# -------------------------------------------------
data "aws_iam_policy_document" "ec2-policy" {
  statement {
    sid = "1"

    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}