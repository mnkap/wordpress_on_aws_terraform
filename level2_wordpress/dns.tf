data "aws_route53_zone" "main" {
  name = "aman-testlab.link"
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.id
  name    = "www.${data.aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [module.alb.lb_dns_name]
}