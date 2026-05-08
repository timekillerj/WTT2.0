provider "aws" {
  region = var.region
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name   = "wiz-task-eks"
  instance_type  = "t3.small"
  s3_bucket_name = var.s3_bucket_name

}

# Create the VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "wiz-task-vpc"

  cidr = "10.0.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]

  private_subnets = ["10.0.1.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.2.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}


# Define the S3 bucket
resource "aws_s3_bucket" "db_backups" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "DBBackupsBucket"
  }
}

resource "aws_s3_bucket_public_access_block" "mongo_backups" {
  bucket = aws_s3_bucket.mongo_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Define the S3 bucket policy to allow public read access
resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.db_backups.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.db_backups.id}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.mongo_backups
  ]
}

# Define the S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "mongo_public_access_block" {
  bucket                  = aws_s3_bucket.db_backups.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_ecr_repository" "tornado_webapp" {
  name = "tornado-webapp"
}

