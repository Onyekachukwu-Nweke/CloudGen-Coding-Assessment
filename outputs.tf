output "rds_endpoint" {
  value = aws_db_instance.db_server.endpoint
}

output "alb_dns_name" {
  value = aws_alb.cloudgen-alb.dns_name
}