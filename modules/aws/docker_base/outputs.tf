output "instance_private_ip_addr" {
  value = aws_instance.docker-base.private_ip
}

output "instance_public_ip_addr" {
  value = aws_instance.docker-base.public_ip
}

output "instance_id" {
  value = aws_instance.docker-base.id
}
