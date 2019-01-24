terraform {
  backend "s3" {
    bucket = "twmartin-terraform-backend"
    key = "bc-challenge.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_ecs_cluster" "ecs_bc_challenge" {
  name = "ecs-bc-challenge"
}

resource "aws_iam_role" "ecs_bc_challenge_task_exec_role" {
  name = "ecs-bc-challenge-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_bc_challenge_task_exec_role_policy" {
  name = "ecs-bc-challenge-task-exec-role-policy"
  role = "${aws_iam_role.ecs_bc_challenge_task_exec_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ecs_task_definition" "ecs_bc_challenge_task" {
  family = "ecs-bc-challenge-task"
  container_definitions = "${file("terraform-files/ecs-task-definition.json")}"
  execution_role_arn = "${aws_iam_role.ecs_bc_challenge_task_exec_role.arn}"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256",
  memory = "512"
}

resource "aws_ecs_service" "ecs_bc_challenge_service" {
  name = "ecs-bc-challenge-service"
  cluster = "${aws_ecs_cluster.ecs_bc_challenge.id}"
  task_definition = "${aws_ecs_task_definition.ecs_bc_challenge_task.arn}"
  desired_count = 2
  launch_type = "FARGATE"
  load_balancer {
    target_group_arn = "${aws_alb_target_group.bc_challenge_target_group.arn}"
    container_name = "bc-challenge-nginx"
    container_port = 80
  }
  network_configuration {
    assign_public_ip = true
    subnets = "${var.subnets}"
    security_groups = ["${aws_security_group.bc_challenge_service_sg.id}"]
  }
}

resource "aws_alb_target_group" "bc_challenge_target_group" {
  name = "bc-challenge-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = "${var.vpc}"
  target_type = "ip"
  deregistration_delay = 5
  depends_on = [
    "aws_alb.bc_challenge_alb",
  ]
}

resource "aws_alb" "bc_challenge_alb" {
  name = "bc-challenge-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.bc_challenge_alb_sg.id}"]
  subnets = "${var.subnets}"
}

resource "aws_alb_listener" "bc_challenge_alb_listener_443" {
  load_balancer_arn = "${aws_alb.bc_challenge_alb.arn}"
  port = "443"
  protocol = "HTTPS"
  certificate_arn = "${var.acm_certificate_arn}"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  default_action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.bc_challenge_target_group.arn}"
  }
}

resource "aws_alb_listener" "bc_challenge_alb_listener_80" {
  load_balancer_arn = "${aws_alb.bc_challenge_alb.arn}"
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "bc_challenge_alb_sg" {
  name = "bc-challenge-alb-sg"
  description = "Allow all HTTP traffic through bc-challenge-alb"
  vpc_id = "${var.vpc}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bc-challenge-alb-sg"
  }
}

resource "aws_security_group" "bc_challenge_service_sg" {
  name = "bc-challenge-service-sg"
  description = "Allow all HTTP traffic from bc-challenge-alb"
  vpc_id = "${var.vpc}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.bc_challenge_alb_sg.id}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bc-challenge-service-sg"
  }
}

resource "aws_cloudwatch_log_group" "bc_challenge_log_group" {
  name = "/ecs/bc-challenge"
  retention_in_days = 7
}

resource "aws_route53_record" "bc_challenge_route53_record" {
  zone_id = "${var.route53_hosted_zone_id}"
  name = "${var.route53_a_record_name}"
  type = "A"
  alias {
    name = "${aws_alb.bc_challenge_alb.dns_name}"
    zone_id = "${aws_alb.bc_challenge_alb.zone_id}"
    evaluate_target_health = false
  }
}
