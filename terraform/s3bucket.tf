# Define the S3 bucket
resource "aws_s3_bucket" "db_backups" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "DBBackupsBucket"
  }
}

# Turn off safety controls
resource "aws_s3_bucket_public_access_block" "mongo_backups" {
  bucket = aws_s3_bucket.db_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Define the S3 bucket policy to allow public read access
resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.db_backups.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPublicList"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.db_backups.id}"
      },
      {
        Sid       = "AllowPublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.db_backups.id}/*"
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
