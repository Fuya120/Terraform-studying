# NATインスタンスのセキュリティグループ作成
resource "aws_security_group" "nat" {
  name        = "nat-sg"
  description = "security-group for NAT"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-nat-sg"
  }

  # インバウンド設定
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # すべてのプロトコル
    cidr_blocks = [var.vpc_cidr]
  }

  # アウトバウンド設定
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # すべてのプロトコル
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALBのセキュリティグループ作成
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "security-group for ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }

  # インバウンド設定
  ingress { 
    description = "HTTP from all"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress { 
    description = "HTTPS from all"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # アウトバウンド設定
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # すべてのプロトコル
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# WEBサーバのセキュリティグループ作成
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "security-group for WEB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-web-sg"
  }

  # インバウンド設定
  ingress { 
    description = "HTTP from alb"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id] 
  }

  # アウトバウンド設定
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # すべてのプロトコル
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# APサーバのセキュリティグループ作成
resource "aws_security_group" "ap" {
  name        = "ap-sg"
  description = "security-group for AP"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-ap-sg"
  }

  # インバウンド設定
  ingress { 
    description = "HTTP from WEB"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.web.id] 
  }

  # アウトバウンド設定
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # すべてのプロトコル
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# DBサーバのセキュリティグループ作成
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "security-group for DB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-db-sg"
  }

  # インバウンド設定
  ingress { 
    description = "HTTP from AP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ap.id] 
  }

  # アウトバウンド設定
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # すべてのプロトコル
    cidr_blocks = ["0.0.0.0/0"]
  }
}