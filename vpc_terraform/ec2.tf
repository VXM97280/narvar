# # ------------------------------------
# # test-narvar IAM Role
# # ------------------------------------
# resource "aws_iam_instance_profile" "test_narvar_profile" {
#   name = "${var.tag_environment}-${var.tag_name}"
#   role = "${aws_iam_role.test_narvar_role.name}"
# }

# resource "aws_iam_role" "test_narvar_role" {
#   name               = "${var.tag_environment}-${var.tag_name}"
#   assume_role_policy = "${data.aws_iam_policy_document.ec2-policy.json}"
# }

# resource "aws_iam_role_policy_attachment" "test_narvar_access_policy_attachment" {
#   role       = "${aws_iam_role.test_narvar_role.name}"
#   policy_arn = "${var.cloudwatch_put_metric_anywhere_arn}"
# }

# ------------------------------------
# test-narvar-ec2 launch configuration
# # -------------------------------------
resource "aws_launch_configuration" "test_narvar_ec2_lc" {
  name                 = "${var.tag_environment}-${var.tag_name}-ec2-lc"
  image_id             = "${var.ubuntu_ami_id}"
  instance_type        = "${var.ec2_instance_type}"
  //iam_instance_profile = "${aws_iam_instance_profile.test_narvar_profile.name}"
  user_data            = "{\"autoScalingGroup\": \"${var.tag_environment}-${var.tag_name}\"}"
  key_name             = "test-narvar-vmalladi"

  root_block_device = [
    {
      volume_size = "8"
      volume_type = "gp2"
    },
  ]

  security_groups = [
    "${aws_security_group.test_narvar_default_sg.id}", 
    "${aws_security_group.test_narvar_asg_sg.id}", 
  ]
}

resource "aws_launch_configuration" "test_narvar_ec2_lcf" {
  name                 = "${var.tag_environment}-${var.tag_name}-ec2-20181006"
  image_id             = "${var.ubuntu_ami_id}"
  instance_type        = "${var.ec2_instance_type}"
  //iam_instance_profile = "${aws_iam_instance_profile.test_narvar_profile.name}"
  user_data            = "{\"autoScalingGroup\": \"${var.tag_environment}-${var.tag_name}\"}"
  key_name             = "test-narvar-vmalladi"

  root_block_device = [
    {
      volume_size = "8"
      volume_type = "gp2"
    },
  ]

  security_groups = [
    "${aws_security_group.test_narvar_default_sg.id}",
  ]
}

# # ------------------------------------
# # test-narvar-asg auto scalling group
# # -------------------------------------
resource "aws_autoscaling_group" "test_narvar_asg" {
  name                = "${var.tag_environment}-${var.tag_name}-asg"
  vpc_zone_identifier = ["${aws_subnet.private_az2.id}","${aws_subnet.private_az3.id}"]

  load_balancers       = ["${aws_elb.test_narvar_elb.name}"]
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance"]

  min_size                  = 1
  max_size                  = 1
  wait_for_capacity_timeout = 0

  launch_configuration      = "${aws_launch_configuration.test_narvar_ec2_lcf.name}"
  enabled_metrics           = ["GroupInServiceInstances", "GroupTerminatingInstances", "GroupPendingInstances", "GroupDesiredCapacity", "GroupStandbyInstances", "GroupMinSize", "GroupMaxSize", "GroupTotalInstances"]
  health_check_type         = "EC2"

  tags = [
    {
      key                 = "Name"
      value               = "${var.tag_environment}-${var.tag_name}-ec2"
      propagate_at_launch = true
    },
    {
      key                 = "Terraform"
      value               = "true"
      propagate_at_launch = true
    },
  ]
}

# ------------------------------------
# test-narvar-asg load balancers
# -------------------------------------
resource "aws_elb" "test_narvar_elb" {
  name               = "${var.tag_environment}-${var.tag_name}-lb"
  subnets = ["${aws_subnet.public_az2.id}","${aws_subnet.public_az3.id}"]
  security_groups = ["${aws_security_group.test_narvar_elb_sg.id}"]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  # listener {
  #   instance_port      = 8000
  #   instance_protocol  = "http"
  #   lb_port            = 443
  #   lb_protocol        = "https"
  #   ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  # }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name            = "${var.tag_environment}-${var.tag_name}-lb"
    Terraform       = "true"
  }
}
# ------------------------------------
# test-narvar-nat nat instance
# # -------------------------------------
resource "aws_instance" "nat_instance" {
  ami           = "${var.nat_ubuntu_ami_id}"
  instance_type = "t1.micro"
  subnet_id = "${aws_subnet.public_az2.id}"
  source_dest_check = "false"
  key_name             = "test-narvar-vmalladi"
  root_block_device = [
    {
      volume_size = "8"
      volume_type = "gp2"
    },
  ]  
  security_groups = [
    "${aws_security_group.test_narvar_nat_sg.id}"
  ]

  tags {
    Name = "${var.tag_environment}-${var.tag_name}-nat"
    Terrafrom = "true"
  }
}