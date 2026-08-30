output "vpcid" {
  value = aws_vpc.fvpc.id
}

output "igw" {
  value = aws_internet_gateway.igw.id
}

output "public_subnet_id"{
  value = aws_subnet.public_sub.id
}

output "priave_subnet_id"{
  value = aws_subnet.private_sub.id
}

output "public_route_table"{
  value = aws_route_table.pub_route_table.id
}

output "private_route_table"{
  value = aws_route_table.pri_route_table.id
}

output "EC2_SG" {
  value = aws_security_group.Project_ec2_SG.id

}

output "EC2_Instance_ID" {
  value = aws_instance.project_ec2.id

}

output "RDS_MYSQL_Security_Group" {
  value = aws_security_group.Project_rds_SG.id

}

output "rds_instance_id" {
  value = aws_db_instance.project_mysql.id
}

output "rds_endpoint" {
  value = aws_db_instance.project_mysql.endpoint
}

output "rds_port" {
  value = aws_db_instance.project_mysql.port
}

output "rds_database_name" {
  value = aws_db_instance.project_mysql.db_name
}