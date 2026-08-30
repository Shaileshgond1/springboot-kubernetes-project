variable "region"{
  description = "This is region"
  type = string
}

variable "awscidr" {
  description = "This is used for vpc cidr"
  type = string
}

variable "pub_sub_cidr" {

  description = "Public subnet CIDR"
  type= string

}

variable "pri_sub_cidr" {

  description = "Public subnet CIDR"
  type= string

}

variable "pri_sub_cidr1" {

  description = "Public subnet CIDR"
  type= string

}



variable "amiid" {
  description = "This is used for vpc cidr"
  type = string
}

variable "instancetype" {

  description = "Instace type of ec2"
  type = string

}


variable "db_name" {

  description = "RDS_DB_NAME"
  type = string

}

variable "username" {

  description = "RDS_DB_USERNAME"
  type = string

}

variable "password" {

  description = "RDS_DB_PASSWORD"
  type = string

}

variable "instace_type_db" {

  description = "RDS_INSTACE_TYPE"
  type = string

}























