terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}

locals {
  dns_zones = {
    for dns_zone in var.dns_entry : dns_zone.zone_name => dns_zone
  }

  dns_records_list = flatten([
    for dns_zone_name, dns_records in local.dns_zones : [
      for dns_record_name, dns_record in dns_records.dns_records :
      merge(dns_record, { zone_name = dns_zone_name }, { name = dns_record_name })
    ]
  ])

  dns_records = {
    for dns_record in local.dns_records_list : dns_record.name => dns_record
  }
}

resource "aws_route53_zone" "this" {
  for_each = local.dns_zones

  name = each.value.zone_name

  dynamic "vpc" {
    for_each = toset(lookup(each.value, "vpc", []))

    content {
      vpc_id = vpc.key
    }
  }

  tags = each.value.tags
}


resource "aws_route53_record" "this" {
  for_each = local.dns_records

  zone_id        = aws_route53_zone.this[each.value.zone_name].id
  name           = each.value.name
  type           = each.value.type
  ttl            = 300
  set_identifier = lookup(each.value, "set_identifier", null)
  records        = each.value.records

  dynamic "geolocation_routing_policy" {
    for_each = lookup(each.value, "geolocation_routing_policy", {})

    content {
      country   = lookup(each.value.geolocation_routing_policy, "country", null)
      continent = lookup(each.value.geolocation_routing_policy, "continent", null)
    }
  }
}

