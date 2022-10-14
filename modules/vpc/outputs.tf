output "vpc_id" {
  value = aws_vpc.sungjunyoung.id
}

output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}