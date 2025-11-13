# The Cheese Factory – Despliegue Profesional con Terraform (v3)

Actividad **AUY1103 – Infraestructura como código**

**Alumna:** Lucía Villalobos  
**Región AWS:** us-east-1  

---

## 1. Descripción general

Este repositorio implementa la infraestructura de “The Cheese Factory” usando **Terraform** con buenas prácticas:

- VPC personalizada (no se usa la VPC por defecto).
- 3 subredes públicas + 3 subredes privadas.
- Application Load Balancer (ALB) público.
- 3 instancias EC2 en subredes **privadas**, detrás del ALB.
- Grupos de seguridad con **principio de mínimo privilegio**.
- Backend remoto en **S3 + DynamoDB** para el estado de Terraform.
- Manejo de entornos `dev` y `prod` mediante la variable `environment`.

---

## 2. Estructura del repositorio

```text
cheese-factory-terraform-v3/
├─ README.md
├─ .gitignore
├─ s3-backend-bootstrap/
│  ├─ main.tf
│  ├─ providers.tf
│  ├─ outputs.tf
│  └─ versions.tf
└─ cheese-factory-infra/
   ├─ providers.tf
   ├─ variables.tf
   ├─ vpc.tf
   ├─ security.tf
   ├─ alb.tf
   ├─ ec2.tf
   ├─ outputs.tf
   ├─ terraform.tfvars.example

```

s3-backend-bootstrap: crea el bucket S3 y la tabla DynamoDB para el estado remoto de Terraform usando el módulo público terraform-aws-modules/s3-bucket/aws.

cheese-factory-infra: crea la VPC, subredes, SG, ALB y EC2, usando como backend el bucket creado antes.

---

## 3. Variables y archivos .tfvars

En variables.tf se define la variable requerida por el enunciado:

```
variable "environment" {
  type    = string
  default = "dev"
}

```

En los locals se utiliza una expresión condicional para el tipo de instancia:

```
locals {
  # dev -> t2.micro, prod -> t3.small
  instance_type = var.environment == "prod" ? "t3.small" : "t2.micro"
}

```

Y se usa en las EC2:

```
resource "aws_instance" "web" {
  count         = 3
  instance_type = local.instance_type
  # ...
}
```

Se incluye el archivo de ejemplo terraform.tfvars.example:

```
environment = "dev"
aws_region  = "us-east-1"
my_ip       = "X.X.X.X/32" # Reemplazar por la IP pública del alumno

```

**En la ejecución real se utiliza terraform.tfvars (local, ignorado por Git) para setear environment, aws_region y my_ip.**

---

## 4. Módulo público VPC y distribución de recursos

En vpc.tf se usa el módulo público:

- terraform-aws-modules/vpc/aws

Se crean:

- 1 VPC propia 10.0.0.0/16

- 3 subredes públicas (para el ALB)

- 3 subredes privadas (para las EC2)

- NAT Gateway para salida a internet de las subredes privadas

**El ALB utiliza module.vpc.public_subnets y las EC2 module.vpc.private_subnets, cumpliendo el requisito del enunciado.**

---

## 5. Backend remoto (S3 + DynamoDB)

En s3-backend-bootstrap se usa el módulo público:

- terraform-aws-modules/s3-bucket/aws

El bucket:

- Es privado.

- Tiene versionamiento habilitado.

- Tiene bloqueo de acceso público.

**Además, se crea la tabla DynamoDB tf-lock-cheese para el lock del estado.**

En cheese-factory-infra/providers.tf el backend se configura así:

```
terraform {
  backend "s3" {
    bucket         = "cheese-tfstate-global-339712780971"
    key            = "global/cheese/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-cheese"
    encrypt        = true
  }
}

```

---

## 6. Seguridad (Security Groups)

En security.tf se implementan dos SG:

**SG del ALB**

- Permite HTTP (80) desde 0.0.0.0/0.

```
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

```

**SG de las EC2**

- HTTP (80) solo desde el SG del ALB.

- SSH (22) solo desde la IP pública del alumno (my_ip).

```
ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.alb_sg.id]
}

ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [var.my_ip]
}

```

Esto cumple el principio de mínimo privilegio pedido en la actividad.

---

## 7. Funciones nativas de Terraform

Se usan funciones como:

```
# Nombres de recursos
Name = format("%s-web-%d", local.name_prefix, count.index + 1)

# Fusión de etiquetas
tags = merge(local.common_tags, { Name = ... })

# Cantidad de adjuntos al target group
count = length(aws_instance.web)

```

Con esto se cubre el requisito de utilizar funciones nativas (format, merge, length) de forma coherente.

**8. Comandos para desplegar**


**1️⃣ Backend (una sola vez)**

```
cd s3-backend-bootstrap
terraform init
terraform apply -auto-approve

```

**2️⃣ Infraestructura principal**

```
cd ../cheese-factory-infra
terraform init -reconfigure
terraform plan
terraform apply -auto-approve

```

Al final:

```

terraform output
# alb_dns_name = "cheese-dev-alb-XXXX.us-east-1.elb.amazonaws.com"

```

Acceso vía navegador:

```

http://<alb_dns_name>

```

---

## 9. Cambio de dev a prod

Para cambiar a entorno prod, editar terraform.tfvars local:

```
environment = "prod"

```

Ejecutar nuevamente:

```
terraform plan
terraform apply -auto-approve

```

