provider "aws" {
    access_key = ""
    secret_key ="T"
    region = "us-east-2" 
}

variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  type        = string
}

variable "aws_availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" 
}

resource "aws_subnet" "my_sub" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.subnet_cidr_block
  availability_zone       = var.aws_availability_zone
}

resource "aws_security_group" "protection_gr" {
  name        = "protection_gr"
  description = "Security group for web servers"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_instance" "prom_server" {
    ami = "ami-08333bccc35d71140"  
    instance_type = "t2.micro"        
    subnet_id  = aws_subnet.my_sub
    key_name  = "Khrust1a"   
    vpc_security_group_ids = [aws_security_group.protection_gr.id]

  user_data = <<-EOF
              #!/bin/bash
              # Оновлюємо пакетний менеджер
              apt-get update -y

              apt-get install -y prometheus

              cat <<EOT > /etc/prometheus/prometheus.yml
              global:
                scrape_interval: 15s
                evaluation_interval: 15s

              scrape_configs:
                - job_name: 'node-exporter'
                  static_configs:
                    - targets: ['localhost:9100']

                - job_name: 'cadvisor-exporter'
                  static_configs:
                    - targets: ['localhost:8080']
              EOT

              systemctl enable prometheus
              systemctl start prometheus

              apt-get install -y node-exporter
              systemctl enable node-exporter
              systemctl start node-exporter

              apt-get install -y cadvisor
              systemctl enable cadvisor
              systemctl start cadvisor
              EOF
}

resource "aws_instance" "NodeAndCadvizor" {
  ami = "ami-08333bccc35d71140" 
  instance_type = "t2.micro"        
  subnet_id  = aws_subnet.my_sub.id
  key_name  = "Khrust1a"   
  vpc_security_group_ids = [aws_security_group.protection_gr.id]

  user_data = <<-EOF
                #!/bin/bash
                apt-get update -y

                apt-get install -y node-exporter cadvisor

                systemctl enable node-exporter
                systemctl start node-exporter

                systemctl enable cadvisor
                systemctl start cadvisor
              EOF
}
