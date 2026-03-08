output "nat_1a_instance_public_ip" {
  description = "NATインスタンス1aのパブリックIP"
  value       = aws_instance.nat_1a.public_ip
}

output "nat_1c_instance_public_ip" {
  description = "NATインスタンス1cのパブリックIP"
  value       = aws_instance.nat_1c.public_ip
}

output "alb_dns_url" {
  description = "ALBのアクセスURL"
  value       = "http://${aws_lb.web_alb.dns_name}"  
}

output "name_servers" {
  description = "ネームサーバー"
  value       = aws_route53_zone.public.name_servers
}