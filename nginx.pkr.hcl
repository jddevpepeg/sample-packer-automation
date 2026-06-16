packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "nginx-base"
}

variable "source_ami_owner" {
  type    = string
  default = "137112381938" # Amazon Linux 2023
}

# ---------------------------------------------------------------------------
# Source
# ---------------------------------------------------------------------------

source "amazon-ebs" "nginx" {
  region        = var.aws_region
  instance_type = var.instance_type
  ami_name      = "${var.ami_name_prefix}-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = [var.source_ami_owner]
    most_recent = true
  }

  ssh_username = "ec2-user"

  tags = {
    Name      = "${var.ami_name_prefix}"
    ManagedBy = "packer"
    OS        = "Amazon Linux 2023"
    Role      = "nginx"
  }
}

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

build {
  name    = "nginx-image"
  sources = ["source.amazon-ebs.nginx"]

  # Run the Ansible playbook against the temporary EC2 instance
  provisioner "ansible" {
    playbook_file = "./ansible/playbook.yml"

    extra_arguments = [
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3",
    ]
  }
}
