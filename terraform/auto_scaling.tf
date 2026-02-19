# WEBサーバのオートスケーリンググループ作成
resource "aws_autoscaling_group" "web_asg" {
  name                      = "${var.project_name}-web-asg"
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 4

  target_group_arns         = [aws_lb_target_group.web_tg.arn]
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = [aws_subnet.web_pri_1a.id, aws_subnet.web_pri_1c.id]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-server"
    propagate_at_launch = true
  }
}

# APサーバのオートスケーリンググループ作成
resource "aws_autoscaling_group" "ap_asg" {
  name                = "${var.project_name}-ap-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 4
  vpc_zone_identifier = [aws_subnet.ap_pri_1a.id, aws_subnet.ap_pri_1c.id]

  launch_template {
    id      = aws_launch_template.ap_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ap-server"
    propagate_at_launch = true
  }
}