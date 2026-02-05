output "instance_public_ip" {
  description = "作成したインスタンスのパブリックIP"
  value       = aws_instance.my_server.public_ip
}
