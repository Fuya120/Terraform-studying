# パブリックホストゾーンの作成
resource "aws_route53_zone" "public" {
  name = "rp-sakai.com"
}

# Aレコードの作成
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "rp-sakai.com"
  type    = "A"

  # エイリアスレコードでALBと結びつける
  alias {
    name                   = aws_lb.web_alb.dns_name
    zone_id                = aws_lb.web_alb.zone_id
    evaluate_target_health = true
  }
}