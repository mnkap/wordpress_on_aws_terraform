output "target_group_arn" {
  value = module.alb.target_group_arns
}

output "load_balancer_security_group" {
  value = aws_security_group.load_balancer.id
}

output "db_instance_endpoint" {
   description = "The connection endpoints for any database instances in this environment."
   value       = module.rds.db_instance_endpoint
}