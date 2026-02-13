resource "aws_lb" "web_alb" {
  name               = "${var.project_name}-alb"
  internal           = false 
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.pub_1a.id, aws_subnet.pub_1c.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"        # チェックしに行くパス（index.htmlなど）
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3          # 3回成功したら「健全」とみなす
    unhealthy_threshold = 2          # 2回失敗したら「異常」とみなす
    timeout             = 5          # 応答待ち（秒）
    interval            = 30         # チェックの間隔（秒）
    matcher             = "200"      # 成功とみなすステータスコード
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}