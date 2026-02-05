variable "aws_region" {
  description = "AWSのリージョン"
  type        = string
}

variable "instance_type" {
  description = "EC2のインスタンスタイプ"
  type        = string
}

variable "instance_name" {
  description = "サーバーの名前"
  type        = string
}

variable "my_ip" {
  description = "マイIP"
  type        = string
}
