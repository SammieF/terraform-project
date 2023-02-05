output "Application_LB_DNS" {
  value = aws_lb.App_LB.dns_name
}

output "Target_group_DNS" {
  value = aws_lb_target_group.target_G.arn
}

output "public1" {
  value = aws_instance.web-server.public_ip
}

output "public2" {
  value = aws_instance.web-server2.public_ip
}

output "public3" {
  value = aws_instance.web-server3.public_ip
}
