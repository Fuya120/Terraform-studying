# NATインスタンス用IAMロールの作成とEC2への許可
resource "aws_iam_role" "nat_role" {
  name = "${var.project_name}-nat-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
    }]
  })
}

# IAMポリシーを上のIAMロールにアタッチする
resource "aws_iam_role_policy_attachment" "nat_ssm_attach" {
  role       = aws_iam_role.nat_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# インスタンスプロファイルにIAMロールを格納（こうしないとEC2にIAMロールが付与できない）
resource "aws_iam_instance_profile" "nat_profile" {
  name = "${var.project_name}-nat-profile"
  role = aws_iam_role.nat_role.name
}

# WEBサーバ用
resource "aws_iam_role" "web_role" {
  name = "${var.project_name}-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
    }]
  })
}

resource "aws_iam_role_policy" "web_servicediscovery" {
  name = "${var.project_name}-web-servicediscovery"
  role       = aws_iam_role.web_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetInstancesHealthStatus",
          "servicediscovery:GetNamespace",
          "servicediscovery:GetService",
          "servicediscovery:ListInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "web_ssm_attach" {
  role       = aws_iam_role.web_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web_profile" {
  name = "${var.project_name}-web-profile"
  role = aws_iam_role.web_role.name
}

# APサーバ用
resource "aws_iam_role" "ap_role" {
  name = "${var.project_name}-ap-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
    }]
  })
}

resource "aws_iam_role_policy" "cloudmap_register" {
  name = "${var.project_name}-cloudmap-register"
  role       = aws_iam_role.ap_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "servicediscovery:RegisterInstance",
          "servicediscovery:DiscoverInstances",
          "servicediscovery:DeregisterInstance",
          "servicediscovery:UpdateInstanceCustomHealthStatus",
          "servicediscovery:ListServices",
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetService",
          "servicediscovery:GetNamespace",
          "servicediscovery:GetOperation",
          "route53:CreateHealthCheck",
          "route53:DeleteHealthCheck",
          "route53:GetHealthCheck",
          "route53:UpdateHealthCheck"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ap_ssm_attach" {
  role       = aws_iam_role.ap_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ap_profile" {
  name = "${var.project_name}-ap-profile"
  role = aws_iam_role.ap_role.name
}
