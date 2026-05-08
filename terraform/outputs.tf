output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "instance_public_ip" {
  value = aws_instance.mongo-server.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.db_backups.bucket
}

output "s3_bucket_url" {
  value = "https://${aws_s3_bucket.db_backups.bucket}.s3.amazonaws.com"
}

output "ecr_repo_arn" {
  value       = aws_ecr_repository.tornado_webapp.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.tornado_webapp.repository_url
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}