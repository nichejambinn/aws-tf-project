output "vpc_id" { value = aws_vpc.vpc-shared.id }
output "private_subnets" { value = aws_subnet.private[*] }
output "public_subnets" { value = aws_subnet.public[*] }


