provider "aws" {
  region = "us-east-1"
}

data "aws_ssm_parameter" "ami_id" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.cidr_vpc

  azs            = var.azs
  public_subnets = var.public_subnets
}


resource "aws_security_group" "my-sg" {
  vpc_id = module.vpc.vpc_id
  name   = join("_", ["sg", module.vpc.vpc_id])
  dynamic "ingress" {
    for_each = var.rules
    content {
      from_port   = ingress.value["port"]
      to_port     = ingress.value["port"]
      protocol    = ingress.value["proto"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = join("_", ["Dynamic-SG", module.vpc.vpc_id])
  }
}

resource "aws_instance" "my-instance" {
  ami             = data.aws_ssm_parameter.ami_id.value
  subnet_id       = module.vpc.public_subnets[0]
  instance_type   = var.instance_type
  security_groups = [aws_security_group.my-sg.id]
  user_data       = fileexists("script.sh") ? file("script.sh") : null
}
