output "cluster_id" {
  value = aws_eks_cluster.techpilotz.id
}

output "node_group_id" {
  value = aws_eks_node_group.techpilotz.id
}

output "vpc_id" {
  value = aws_vpc.techpilotz_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.techpilotz_subnet[*].id
}