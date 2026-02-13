# WEBサーバの起動テンプレート作成
resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.project_name}-web-lt" # 「name」ではなくこっち。テンプレートを更新した際に、古いものを消す前に新しいものを作れるようにするため
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf install -y nginx

              cat <<'INNER_EOF' > /etc/nginx/nginx.conf
              user nginx;
              worker_processes auto;
              error_log /var/log/nginx/error.log notice;
              pid /run/nginx.pid;

              include /usr/share/nginx/modules/*.conf;

              events {
                  worker_connections 1024;
              }

              http {
                  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                                    '$status $body_bytes_sent "$http_referer" '
                                    '"$http_user_agent" "$http_x_forwarded_for"';

                  access_log  /var/log/nginx/access.log  main;

                  sendfile            on;
                  tcp_nopush          on;
                  keepalive_timeout   65;
                  types_hash_max_size 4096;

                  include             /etc/nginx/mime.types;
                  default_type        application/octet-stream;

                  include /etc/nginx/conf.d/*.conf;
              }
              INNER_EOF

              cat <<'INNER_EOF' > /etc/nginx/conf.d/app_proxy.conf
              server {
                  listen       80;

                  # Load configuration files for the default server block.
                  include /etc/nginx/default.d/*.conf;

                  error_page 404 /404.html;
                  location = /404.html {
                  }

                  error_page 500 502 503 504 /50x.html;
                  location = /50x.html {
                  }

                  location / {
                  proxy_pass http://${aws_service_discovery_service.main.name}.${aws_service_discovery_private_dns_namespace.main.name};
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  }
              }
              INNER_EOF

              systemctl enable nginx
              systemctl start nginx

              echo "<h1>Hello from Web Server in ${var.project_name}</h1>" > /usr/share/nginx/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-web-server"
    }
  }

  # 新しいテンプレートを作成してから、古いのを削除するようにする
  lifecycle {
    create_before_destroy = true
  }
}

# APサーバの起動テンプレート作成
# resource "aws_launch_template" "ap_lt" {
#   name_prefix   = "${var.project_name}-ap-lt" # 「name」ではなくこっち。テンプレートを更新した際に、古いものを消す前に新しいものを作れるようにするため
#   image_id      = data.aws_ami.al2023.id
#   instance_type = var.instance_type

#   iam_instance_profile {
#     name = aws_iam_instance_profile.ssm_profile.name
#   }

#   vpc_security_group_ids = [aws_security_group.ap_sg.id]

#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               dnf install -y php
#               systemctl enable php-fpm
#               systemctl start php-fpm
#               echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
#               EOF
#   )

#   tag_specifications {
#     resource_type = "instance"

#     tags = {
#       Name = "${var.project_name}-ap-server"
#     }
#   }

#   # 新しいテンプレートを作成してから、古いのを削除するようにする
#   lifecycle {
#     create_before_destroy = true
#   }
# }