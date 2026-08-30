provider "aws" {
  region = var.region
}

resource "aws_vpc" "fvpc"{

  cidr_block = var.awscidr
  tags= {
    Name = "project_vpc"  
  }

}


resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.fvpc.id
  tags = {
    Name = "project-igw"
  }

}

resource "aws_subnet" "public_sub" {

  vpc_id = aws_vpc.fvpc.id
  cidr_block = var.pub_sub_cidr
  availability_zone = "ca-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_sub" {

  vpc_id = aws_vpc.fvpc.id
  cidr_block = var.pri_sub_cidr
  availability_zone = "ca-central-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_subnet" "private_sub0" {

  vpc_id = aws_vpc.fvpc.id
  cidr_block = var.pri_sub_cidr1
  availability_zone = "ca-central-1d"
  map_public_ip_on_launch = false
  tags = {
    Name = "private_subnet0"
  }
}


resource "aws_route_table" "pub_route_table" {

  vpc_id = aws_vpc.fvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {

    Name = "public_RT"

  }
}

resource "aws_route_table" "pri_route_table" {

  vpc_id = aws_vpc.fvpc.id

  tags = {

    Name = "private_RT"

  }
}

resource "aws_route_table" "pri_route_table0" {

  vpc_id = aws_vpc.fvpc.id

  tags = {

    Name = "private_RT0"

  }
}


resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.pub_route_table.id
}


resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_route_table.pri_route_table.id
}

resource "aws_route_table_association" "private_assoc0" {
  subnet_id      = aws_subnet.private_sub0.id
  route_table_id = aws_route_table.pri_route_table0.id
}


resource "aws_security_group" "Project_ec2_SG" {

  vpc_id = aws_vpc.fvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "Project_ec2_SG"
  }
}


resource "aws_instance" "project_ec2" {

  ami           = var.amiid
  instance_type = var.instancetype

  subnet_id = aws_subnet.public_sub.id

  vpc_security_group_ids = [
    aws_security_group.Project_ec2_SG.id
  ]

  associate_public_ip_address = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "minikube"
  }
}


resource "aws_security_group" "Project_rds_SG" {

  name   = "project-rds-sg"
  vpc_id = aws_vpc.fvpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.Project_ec2_SG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Project_RDS_SG"
  }
}

resource "aws_db_subnet_group" "mysql_subnet_group" {

  name = "project-mysql-subnet-group"

  subnet_ids = [
    aws_subnet.private_sub.id,
    aws_subnet.private_sub0.id
  ]

  tags = {
    Name = "Project-MySQL-Subnet-Group"
  }
}

resource "aws_db_instance" "project_mysql" {

  identifier = "project-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = var.instace_type_db

  allocated_storage = 30
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.username
  password = var.password

  db_subnet_group_name = aws_db_subnet_group.mysql_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.Project_rds_SG.id
  ]

  publicly_accessible = false

  skip_final_snapshot = true

  tags = {
    Name = "Project-MySQL"
  }
}

