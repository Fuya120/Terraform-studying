variable "instance_type" {
  description = "EC2のインスタンスタイプ"
  type        = string
}

variable "my_ip" {
  description = "マイIP"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCの範囲"
  type        = string
} 

variable "ssh_host_alias" {
  description = "SSH接続先の別名"
  type        = string
}

variable "project_name" {
  description = "リソースに付けられる共通のプロジェクト名"
  type        = string
}