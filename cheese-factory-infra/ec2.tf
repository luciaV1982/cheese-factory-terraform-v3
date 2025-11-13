# Buscar la AMI más reciente de Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"] # Cuenta oficial de Amazon Linux

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "web" {
  count = 3

  ami           = data.aws_ami.al2023.id
  instance_type = local.instance_type
  subnet_id     = module.vpc.private_subnets[count.index]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    dnf -y update
    #dnf -y install nginx
    dnf -y install docker
    #systemctl enable nginx
    #systemctl start nginx
    systemctl enable docker
    systemctl start docker

    # Página personalizada
    #cat > /usr/share/nginx/html/index.html << 'HTML'
    #<!DOCTYPE html>
    #<html>
    #<head>
    #  <meta charset="UTF-8">
    #  <title>The Cheese Factory - ${var.environment}</title>
    #  <style>
    #    body {
    #      font-family: Arial, sans-serif;
    #      background: #fff7dc;
    #      color: #333;
    #      text-align: center;
    #      padding-top: 60px;
    #    }
    #    h1 { font-size: 40px; margin-bottom: 10px; }
    #    h2 { font-size: 24px; margin-bottom: 30px; }
    #    p { font-size: 16px; }
    #    .card {
    #      display: inline-block;
    #      padding: 20px 30px;
    #      border-radius: 12px;
    #      background: #ffffff;
    #      box-shadow: 0 4px 10px rgba(0,0,0,0.1);
    #    }
    #  </style>
    #</head>
    #<body>
    #  <div class="card">
    #    <h1>The Cheese Factory</h1>
    #    <h2>Environment: ${var.environment}</h2>
    #    <p>Infraestructura desplegada con Terraform (VPC, ALB, EC2 privadas).</p>
    #  </div>
    #</body>
    #</html>
    #HTML

    # Ejecutar contenedor según índice
    index=${count.index}
    if [ "$index" -eq 0 ]; then
      docker run -d -p 80:80 errm/cheese:wensleydale
    elif [ "$index" -eq 1 ]; then
      docker run -d -p 80:80 errm/cheese:cheddar
    elif [ "$index" -eq 2 ]; then
      docker run -d -p 80:80 errm/cheese:stilton
    fi
  EOF

  tags = merge(
    local.common_tags,
    {
      Name = format("%s-web-%d", local.name_prefix, count.index + 1)
    }
  )
}
# Adjuntar cada instancia al Target Group del ALB
resource "aws_lb_target_group_attachment" "web_attachments" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}


