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

# APサーバを通常リソースのインスタンスで作成
resource "aws_instance" "ap_server_1a" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ap_sg.id]
  subnet_id              = aws_subnet.ap_pri_1a.id
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  #phpのインストール
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install php php-fpm httpd -y # Apacheもインストールすることで、APサーバ側での作業が不要になる

              systemctl start httpd
              systemctl enable httpd
              systemctl start php-fpm
              systemctl enable php-fpm

              echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
              EOF

  tags = {
    Name = "${var.project_name}-ap-server-1a"
  }
}

resource "aws_instance" "ap_server_1c" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ap_sg.id]
  subnet_id              = aws_subnet.ap_pri_1c.id
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  #phpのインストール
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install php php-fpm httpd -y # Apacheもインストールすることで、APサーバ側での作業が不要になる

              systemctl start httpd
              systemctl enable httpd
              systemctl start php-fpm
              systemctl enable php-fpm

              echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
              EOF

  tags = {
    Name = "${var.project_name}-ap-server-1c"
  }
}

# APサーバのオートスケーリンググループ作成
# resource "aws_autoscaling_group" "ap-asg" {
#   name                      = "${var.project_name}-ap-asg"
#   desired_capacity          = 2
#   min_size                  = 1
#   max_size                  = 4

#   target_group_arns         = []
#   health_check_grace_period = 300
#   health_check_type         = "ELB"
#   vpc_zone_identifier       = [aws_subnet.ap_pri_1a.id, aws_subnet.ap_pri_1c.id]

#   launch_template {
#     id      = aws_launch_template.ap_lt.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "Name"
#     value               = "${var.project_name}-ap-asg-server"
#     propagate_at_launch = true
#   }