resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = var.tag_name
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.tag_name}-igw"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.16.0/20"

  tags = {
    Name = "${var.tag_name}-subnet"
    connectivity = "Public"
  }
}

resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.tag_name}-route-table"
  }
}

resource "aws_route" "route_to_igw" {
  route_table_id = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0" 
  gateway_id = aws_internet_gateway.my_igw.id 
}


resource "aws_security_group" "web_server_security_group" {
  name        = "${var.tag_name}-security-group}"
  description = "Security group for the web server"
  vpc_id      = aws_vpc.my_vpc.id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "${var.tag_name}-webserver-sg"
  }

}


resource "aws_route_table_association" "public_subnet_route_table_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id =  aws_route_table.my_route_table.id
}

resource "tls_private_key" "rsa-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_file" {
  filename        = "ec2.pem"
  file_permission = "400"
  content         = tls_private_key.rsa-key.private_key_pem
}

resource "aws_key_pair" "key-pair" {
  key_name   = "key-pair"
  public_key = tls_private_key.rsa-key.public_key_openssh
}

resource "aws_instance" "web_server_instance" {
  ami           = var.instance_ami
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key-pair.key_name
  subnet_id     = aws_subnet.public_subnet.id 
  associate_public_ip_address = true

  # Associate the security group you created
  vpc_security_group_ids = [aws_security_group.web_server_security_group.id]


  connection {
    type        = "ssh"
    user        = "ec2-user" 
    private_key = tls_private_key.rsa-key.private_key_pem 
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install httpd -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
  }

tags = {
    Name = "${var.tag_name}-EC2-instance"
  }
}

# Output the public IP address of the EC2 instance
output "public_ip" {
  value = aws_instance.web_server_instance.public_ip
}