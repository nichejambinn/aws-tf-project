output "vpc-shared_id" { value = aws_vpc.vpc-shared.id }
output "vpc-dev_id" { value = aws_vpc.vpc-dev.id }
output "private_subnets" { value = aws_subnet.private[*] }
output "public_subnets" { value = aws_subnet.public[*] }


