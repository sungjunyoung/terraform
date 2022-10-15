resource "aws_lb" "sungjunyoung_public" {
  name               = "sungjunyoung-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sungjunyoung_public_alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = true

  access_logs {
    enabled = false
    bucket  = ""
  }
}

resource "aws_lb_target_group" "sungjunyoung_public_alb_http" {
  name        = "sungjunyoung-public-alb-http"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    interval            = 30
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = 404
  }
}

resource "aws_lb_target_group_attachment" "sungjunyoung_public_alb_http" {
  for_each = toset(var.nlb_ips)

  target_group_arn = aws_lb_target_group.sungjunyoung_public_alb_http.arn
  target_id        = each.value
}

data "aws_acm_certificate" "sungjunyoung" {
  domain   = "*.sungjunyoung.dev"
  statuses = ["ISSUED"]
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.sungjunyoung_public.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.sungjunyoung.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Bad Reqeust"
      status_code  = "400"
    }
  }
}

resource "aws_lb_listener_rule" "https" {
  listener_arn = aws_alb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sungjunyoung_public_alb_http.arn
  }

  condition {
    host_header {
      values = ["*.sungjunyoung.dev"]
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.sungjunyoung_public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "sungjunyoung_public_alb" {
  name   = "sungjunyoung-public-alb"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}