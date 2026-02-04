variable "aws_region" {
  description = "AWSのリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_type" {
  description = "EC2のインスタンスタイプ"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "サーバーの名前"
  type        = string
  default     = "my-server"
}
