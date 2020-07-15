provider "aws" {
	region = "ap-south-1"
	profile = "yashterra"
}

resource "aws_vpc" "terraform_VPC" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = "true"
}

output "vpcid" {
	value = aws_vpc.terraform_VPC.id
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.terraform_VPC.id
}

output "ig_id" {
	value = aws_internet_gateway.gateway.id 
}

resource "aws_subnet" "subnet-1-1a" {
  vpc_id     = aws_vpc.terraform_VPC.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
}

output "subnet-1-id" {
	value = aws_subnet.subnet-1-1a.id
}

resource "aws_subnet" "subnet-2-1b" {
  vpc_id     = aws_vpc.terraform_VPC.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
}

output "subnet-2-id" {
	value = aws_subnet.subnet-2-1b.id
}

resource "aws_route_table" "terraroute" {
  vpc_id = aws_vpc.terraform_VPC.id
}

output "routeid" {
	value = aws_route_table.terraroute.id
}

resource "aws_route" "routing" {
  route_table_id            = aws_route_table.terraroute.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gateway.id 
}

resource "aws_route_table_association" "associate" {
  subnet_id      = aws_subnet.subnet-1-1a.id
  route_table_id = aws_route_table.terraroute.id
}

resource "aws_eip" "lb" {
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.subnet-1-1a.id
}

output "nat-gateway-id" {
	value = aws_nat_gateway.gw.id
}

resource "aws_route_table" "terraroute-2" {
  vpc_id = aws_vpc.terraform_VPC.id
}

output "routeid-2" {
	value = aws_route_table.terraroute-2.id
}

resource "aws_route" "routing-nat" {
  route_table_id            = aws_route_table.terraroute-2.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id =  aws_nat_gateway.gw.id
}

resource "aws_route_table_association" "associate-2" {
  subnet_id      = aws_subnet.subnet-2-1b.id
  route_table_id = aws_route_table.terraroute-2.id
}

resource "aws_security_group" "wordpress_sg" {
  name        = "allow_required_ports"
  description = "Allow TLS inbound traffic to 8080,80,22"
  vpc_id      = aws_vpc.terraform_VPC.id

 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "sg1_id" {
	value = aws_security_group.wordpress_sg.id
}

resource "aws_security_group" "testing_sg" {
  name        = "testing_sg"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.terraform_VPC.id

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
}

output "testing-sg-id" {
	value = aws_security_group.testing_sg.id
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql_sg"
  description = "Allow sg1 inbound traffic"
  vpc_id      = aws_vpc.terraform_VPC.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.wordpress_sg.id}"]
  }
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.testing_sg.id}"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "mysql-sg-id" {
	value = aws_security_group.mysql_sg.id
}

resource "aws_instance" "wordpress" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1-1a.id
  key_name = "terraform-20200612192017563900000002"
  security_groups = ["${aws_security_group.wordpress_sg.id}"]
}

resource "aws_instance" "mysql" {
  ami           = "ami-76166b19"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-2-1b.id
  key_name = "terraform-20200612192017563900000002"
  security_groups = ["${aws_security_group.mysql_sg.id}"]
}

output "mysql-instance-id" {
	value = aws_instance.mysql.id
}

resource "aws_instance" "testOS" {
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet-1-1a.id
  key_name = "terraform-20200612192017563900000002"
  security_groups = ["${aws_security_group.testing_sg.id}"]
}