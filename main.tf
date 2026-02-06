# リージョン設定
provider "aws" {
  region = "ap-northeast-1"
}

# OS設定
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

# VPC作成
resource "aws_vpc" "tf_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "tf-vpc"
  }
}

# サブネット作成
resource "aws_subnet" "public01" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true # ここで起動するインスタンスにパブリックIPを自動付与
  availability_zone       = "ap-northeast-1a"
  
  tags = {
    Name = "public01"
  }
}

resource "aws_subnet" "private01" {
  vpc_id     = aws_vpc.tf_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "private01"
  }
}

# IGW作成
resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf-igw"
  }
}

# ルートテーブル作成
resource "aws_route_table" "tf_pub_rt" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_igw.id
  }
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "tf-pub-rt"
  }
}

resource "aws_route_table" "tf_pri_rt" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "tf-pri-rt"
  }
}

# ルートテーブルとサブネットを紐づけ
resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.public01.id
  route_table_id = aws_route_table.tf_pub_rt.id
}

resource "aws_route_table_association" "pri" {
  subnet_id      = aws_subnet.private01.id
  route_table_id = aws_route_table.tf_pri_rt.id
}

# キーペア作成
resource "aws_key_pair" "my_key" {
  key_name = "tf-key"
  public_key = file("./terraform-key.pub")
}

# セキュリティグループ作成
resource "aws_security_group" "allow_web" {
  name        = "allow-web"
  description = "allow port for terraform"
  vpc_id      = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf-sg"
  }

  # インバウンド設定
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] 
  }

  ingress { 
    description = "HTTP from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"] 
  }

  # アウトバウンド設定
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # すべてのプロトコル
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# インスタンス作成
resource "aws_instance" "my_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.public01.id

  #Nginxのインストール
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install nginx -y
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Hello,World!?</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = var.instance_name
  }
}
