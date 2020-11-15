
provider "aws" {
  region = "eu-west-2"
  
  access_key = " "
  secret_key = " "

  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}


resource "aws_elb" "elb" {
  name               = "elb"
  subnets          = ["subnet-fc624695"]
  internal           = false

  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:3000/"
    interval            = 30
  }
  
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}


resource "aws_placement_group" "apglifebit" {
  name     = "apglifebit"
  strategy = "spread"
}


resource "aws_launch_configuration" "alclifebit" {
  name_prefix   = "alclifebit"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "123"
  
  
  
}


resource "aws_autoscaling_group" "aaglilifebit-terraform-aag" {
  name                      = "aaglilifebit-terraform-aag"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  placement_group           = aws_placement_group.apglifebit.id
  launch_configuration      = aws_launch_configuration.alclifebit.name
  vpc_zone_identifier       = ["subnet-fc624695"]
  
  load_balancers  = [aws_elb.elb.id]
  
  tag {
    key                 = "lifebit"
    value               = "true"
    propagate_at_launch = true
  }
  
}

resource "aws_autoscaling_policy" "aaglilifebit-scale-up" {
    name = "aaglilifebit-scale-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.aaglilifebit-terraform-aag.name
}

resource "aws_autoscaling_policy" "aaglilifebit-scale-down" {
    name = "aaglilifebit-scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.aaglilifebit-terraform-aag.name
}


resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "mem-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.aaglilifebit-scale-up.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.aaglilifebit-terraform-aag.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "mem-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "300"
    statistic = "Average"
    threshold = "40"
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.aaglilifebit-scale-down.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.aaglilifebit-terraform-aag.name}"
    }
}
