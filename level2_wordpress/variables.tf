variable "env_code" {
  type = string
}

variable "load_balancer_security_group" {
  default = "load_balancer_security_group"
}


variable "db_instance_endpoint" {
  default = "data.terraform_remote_state.level2_wordpress.outputs.db_instance_endpoints"
}

variable "target_group_arn" {
  default = []
  type        = list(string)
}