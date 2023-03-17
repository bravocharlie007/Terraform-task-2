resource "aws_route53_zone" dev_zone {
  name = local.zone_name
#  tags_all = local.zone_tags
}

resource "aws_route53_record" "alias_alb_record" {
  zone_id = aws_route53_zone.dev_zone.zone_id
  name = local.zone_name
  type = "A"

  alias {
    name = aws_lb.lb.dns_name
    zone_id = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}

locals {
  zone_name = "dev.ec2deployer.com"
}