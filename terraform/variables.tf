variable "s3_bucket_name" {
  default = "techtask-public-mongo-backups"
}

variable "github_org" {
  default = "timekillerj"
}

variable "github_repo" {
  default = "WTT2.0"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "eks_cluster_name" {
  default = "wiz-task-eks"
}

variable "node_group_instance_type" {
  default = "t3.small"
}

variable "mongo_ami_id" {
  default = "ami-04a81a99f5ec58529"
}

variable "mongo_instance_type" {
  default = "t2.micro"
}

variable "mongo_key_pair" {
  default = "wiz-task"
}