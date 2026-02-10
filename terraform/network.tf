# VPC作成
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default" # インスタンスを専有ホストにするかどうか決める
  enable_dns_hostnames = true # インスタンスがDNS名を持てるようにする（実務で重要）
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# サブネット作成
resource "aws_subnet" "pub_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # ここで起動するインスタンスにパブリックIPを自動付与
  availability_zone       = "ap-northeast-1a"
  
  tags = {
    Name = "${var.project_name}-public-1a"
  }
}

resource "aws_subnet" "pub_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true # ここで起動するインスタンスにパブリックIPを自動付与
  availability_zone       = "ap-northeast-1c"
  
  tags = {
    Name = "${var.project_name}-public-1c"
  }
}

resource "aws_subnet" "web_pri_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.project_name}-web-private-1a"
  }
}

resource "aws_subnet" "web_pri_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.project_name}-web-private-1c"
  }
}

resource "aws_subnet" "ap_pri_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.project_name}-ap-private-1a"
  }
}

resource "aws_subnet" "ap_pri_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.project_name}-ap-private-1c"
  }
}

resource "aws_subnet" "db_pri_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.project_name}-db-private-1a"
  }
}

resource "aws_subnet" "db_pri_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.project_name}-db-private-1c"
  }
}

# IGW作成
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ルートテーブル作成
resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-pub-rt"
  }
}

resource "aws_route_table" "pri_1a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_1a.primary_network_interface_id
  }

  tags = {
    Name = "${var.project_name}-pri-1a-rt"
  }
}

resource "aws_route_table" "pri_1c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_1c.primary_network_interface_id
  }

  tags = {
    Name = "${var.project_name}-pri-1c-rt"
  }
}

# ルートテーブルとサブネットを紐づけ
resource "aws_route_table_association" "pub" {
  for_each = {
    "1a" = aws_subnet.pub_1a.id
    "1c" = aws_subnet.pub_1c.id
  }
  subnet_id      = each.value
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pri_1a" {
  for_each = {
    "web-1a" = aws_subnet.web_pri_1a.id,
    "ap-1a"  = aws_subnet.ap_pri_1a.id,
    "db-1a"  = aws_subnet.db_pri_1a.id
  }
  subnet_id      = each.value
  route_table_id = aws_route_table.pri_1a.id
}

resource "aws_route_table_association" "pri_1c" {
  for_each = {
    "web-1c" = aws_subnet.web_pri_1c.id,
    "ap-1c"  = aws_subnet.ap_pri_1c.id,
    "db-1c"  = aws_subnet.db_pri_1c.id
  }
  subnet_id      = each.value
  route_table_id = aws_route_table.pri_1c.id
}