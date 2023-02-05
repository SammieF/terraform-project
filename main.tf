#Create a vpc to define your data center inside aws platform 
resource "aws_vpc" "head_vpc" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "making"
  }
}

#Create a subnet inside vpc
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.head_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "headpub1-sub"
  }
}


resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.head_vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "headpriv1-sub"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.head_vpc.id
  cidr_block              = "10.1.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "headpub2-sub"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.head_vpc.id
  cidr_block        = "10.1.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "headpriv2-sub"
  }
}

resource "aws_subnet" "public3" {
  vpc_id                  = aws_vpc.head_vpc.id
  cidr_block              = "10.1.5.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "headpub3-sub"
  }
}

resource "aws_subnet" "private3" {
  vpc_id            = aws_vpc.head_vpc.id
  cidr_block        = "10.1.6.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "headpriv3-sub"
  }

}
#Create a route table inside the custom vpc
resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.head_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "headpub-route"
  }
}

#Create route table association to seperate my public subnet from private subnet
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.pub.id
}

#Create internet gateway inside the vpc
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.head_vpc.id

  tags = {
    Name = "headpub-IGW"
  }
}

#Create a security group for this vpc
resource "aws_security_group" "allow_traffic" {
  name        = "traffic"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.head_vpc.id

  ingress {
    description = "HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
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
    Name = "headweb_pub"
  }
}

#Launch instance to the vpc defined 
resource "aws_instance" "web-server" {
  ami                         = "ami-0aa7d40eeae50c9a9"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1a"
  key_name                    = "Master"
  subnet_id                   = aws_subnet.public1.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.allow_traffic.id]

  provisioner "local-exec" {
    command = "echo ${aws_instance.web-server.public_ip}>> host-inventory"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.public_ip
    private_key = file(var.key_pair)
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> ipaddress.txt"
  }

  tags = {
    Name = "headweb1"
  }
}

resource "aws_instance" "web-server2" {
  ami                         = "ami-0aa7d40eeae50c9a9"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1b"
  key_name                    = "Master"
  subnet_id                   = aws_subnet.public2.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.allow_traffic.id]

  provisioner "local-exec" {
    command = "echo ${aws_instance.web-server2.public_ip}>> host-inventory"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = aws_instance.web-server2.public_ip
    private_key = file(var.key_pair)
  }

  provisioner "local-exec" {
    command = "ansible-playbook --private-key ${var.key_pair} httpd.yml"
  }

  tags = {
    Name = "headweb2"
  }
}

resource "aws_instance" "web-server3" {
  ami                         = "ami-0aa7d40eeae50c9a9"
  instance_type               = "t2.micro"
  availability_zone           = "us-east-1c"
  key_name                    = "Master"
  subnet_id                   = aws_subnet.public3.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.allow_traffic.id]

  provisioner "local-exec" {
    command = "ansible-playbook --private-key ${var.key_pair} httpd.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = aws_instance.web-server3.public_ip
    private_key = file(var.key_pair)
  }

  provisioner "local-exec" {
    command = "ansible-playbook --private-key ${var.key_pair} httpd.yml"
  }

  tags = {
    Name = "headweb3"
  }
}
