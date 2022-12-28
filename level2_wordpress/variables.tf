variable "env_code" {
  type = string
}

variable "load_balancer_security_group" {
  default = "load_balancer_security_group"
}


variable "db_instance_endpoint" {
  default = "db_instance_endpoint"
}
