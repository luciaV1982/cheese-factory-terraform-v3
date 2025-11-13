variable "environment" {
  description = "Entorno: dev o prod"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto para tags y nombres"
  type        = string
  default     = "cheese"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.0.0/16"
}

variable "my_ip" {
  description = "Tu IP pública para SSH (x.x.x.x/32)"
  type        = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  name_prefix = format("%s-%s", var.project_name, var.environment)

  # Condicional dev/prod:
  # - dev  -> t2.micro
  # - prod -> t3.small
  instance_type = var.environment == "prod" ? "t3.small" : "t2.micro"
}
