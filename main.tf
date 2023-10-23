resource "tls_private_key" "example_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "aws_key_pair" "key" {
  key_name = "terrakey"
  public_key = tls_private_key.example_key.public_key_openssh
}
resource "aws_vpc" "my_vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "my-vpc"
  }
}
resource "aws_subnet" "public_sub" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.cidr_block_pub  
  availability_zone = var.aws_zone_pub
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.my_vpc.id  

  tags = {
    Name = "myigw"
  }
}
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "public-rt"
  }
}
resource "aws_route_table_association" "rt" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_security_group" "web_sg" {
  name        = "web"
  description = "Allow http"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "httpC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "tcp"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-pub-sg"
  }
}
resource "aws_instance" "web-server" {
  ami           = var.ami_value  
  instance_type = var.instance_value  
  key_name = aws_key_pair.key.key_name
  subnet_id     = aws_subnet.public_sub.id
  security_groups = [aws_security_group.web_sg.id]

  tags = {
    Name = "web-instance"
  }
   connection {
    type        = "ssh"
    user        = "ubuntu"  
    private_key = tls_private_key.example_key.private_key_pem 
    host        = self.public_ip
}
provisioner "file" {
    source      = "app.py"  
    destination = "/home/ubuntu/app.py"  
  }
   provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }
}
