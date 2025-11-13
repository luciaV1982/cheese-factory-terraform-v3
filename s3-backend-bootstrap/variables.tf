variable "bucket_name" {
  description = "Nombre del bucket S3 para almacenar el estado de Terraform"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para los bloqueos de estado"
  type        = string
}

variable "env" {
  description = "Nombre del entorno (ej. dev, prod, global)"
  type        = string
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
}

