output "vpc_id" { value = aws_vpc.vpc-tf.id }
output "private_subnets" { value = aws_subnet.private[*] }
output "public_subnets" { value = aws_subnet.public[*] }
output "vpc_nat_id" { value = aws_nat_gateway.nat.id }
