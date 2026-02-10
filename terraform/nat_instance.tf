# インスタンス作成
resource "aws_instance" "nat_1a" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.nat.id]
  subnet_id                   = aws_subnet.pub_1a.id
  associate_public_ip_address = true

  # 【重要】自分宛て以外のパケットも転送できるようにする（ルーター化）
  source_dest_check = false

  # 前に作ったインスタンスプロファイル（SSM用）を装着
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  # インスタンス起動時に実行するスクリプト（パケット転送の有効化）
  user_data = <<-EOF
              #!/bin/bash
              # IPフォワーディングを有効化（自分宛じゃなくても、通り抜けを許可）
              echo 1 > /proc/sys/net/ipv4/ip_forward
              
              # iptables（通信制御ツール）を使ってマスカレード（NAT設定）
              # ここではOSが起動するたびに設定が有効になるように記述します
              dnf install -y iptables-services
              systemctl enable iptables
              systemctl start iptables
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              /sbin/iptables-save > /etc/sysconfig/iptables
              EOF

  tags = {
    Name = "${var.project_name}-nat-1a"
  }
}

# インスタンス作成
resource "aws_instance" "nat_1c" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.nat.id]
  subnet_id                   = aws_subnet.pub_1c.id
  associate_public_ip_address = true

  # 【重要】自分宛て以外のパケットも転送できるようにする（ルーター化）
  source_dest_check = false

  # 前に作ったインスタンスプロファイル（SSM用）を装着
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  # インスタンス起動時に実行するスクリプト（パケット転送の有効化）
  user_data = <<-EOF
              #!/bin/bash
              # IPフォワーディングを有効化（自分宛じゃなくても、通り抜けを許可）
              echo 1 > /proc/sys/net/ipv4/ip_forward
              
              # iptables（通信制御ツール）を使ってマスカレード（NAT設定）
              # ここではOSが起動するたびに設定が有効になるように記述します
              dnf install -y iptables-services
              systemctl enable iptables
              systemctl start iptables
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              /sbin/iptables-save > /etc/sysconfig/iptables
              EOF

  tags = {
    Name = "${var.project_name}-nat-1c"
  }
}

#EIP作成
resource "aws_eip" "nat-1a" {
    instance = aws_instance.nat_1a.id
    domain   = "vpc"
    
    tags = {
        Name = "${var.project_name}-nat-1a-eip"
    }
}

resource "aws_eip" "nat-1c" {
    instance = aws_instance.nat_1c.id
    domain   = "vpc"
    
    tags = {
        Name = "${var.project_name}-nat-1c-eip"
    }
}