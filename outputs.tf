output "route53_zone" {
  description = "Zone ID of Route53 zone"
  value       = aws_route53_zone.this
}

output "route53_record" {
  description = "Record of Route53 zone"
  value       = aws_route53_record.this
}
