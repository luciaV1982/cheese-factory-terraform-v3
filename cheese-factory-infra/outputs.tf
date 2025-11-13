output "alb_dns_name" {
  description = "DNS público del Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "web_instance_ids" {
  description = "IDs de las instancias web EC2"
  value       = [for i in aws_instance.web : i.id]
}




