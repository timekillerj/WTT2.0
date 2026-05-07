# Define the IAM role
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Define the IAM policy
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2_policy"
  description = "Policy to allow EC2 actions"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",
          "ec2:*",
          "ssm:*",
          "ssmmessages:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ec2_role_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# Define the IAM instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Define the security group for SSH access
resource "aws_security_group" "ssh_access" {
  name        = "ssh_access"
  description = "Allow SSH access from the internet"

  vpc_id = module.vpc.vpc_id  # Reference the VPC ID from the VPC module

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from any IPv4 address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the security group for MongoDB access
resource "aws_security_group" "mongodb_access" {
  name        = "mongodb_access"
  description = "Allow MongoDB access from within the VPC"

  vpc_id = module.vpc.vpc_id  # Reference the VPC ID from the VPC module

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]  # Allow traffic only from within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the EC2 instance
resource "aws_instance" "mongo-server" {
  ami                    = "ami-04a81a99f5ec58529"
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[0]  # Reference the first public subnet ID from the VPC module
  vpc_security_group_ids = [aws_security_group.ssh_access.id, aws_security_group.mongodb_access.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  key_name               = "wiz-task"

  user_data              = file("mongo.sh")

  tags = {
    Name = "MongoServer"
  }
}

# Allocate an Elastic IP
resource "aws_eip" "mongo_server_eip" {
  domain = "vpc"
}

# Associate the Elastic IP with the EC2 instance
resource "aws_eip_association" "mongo_server_eip_assoc" {
  instance_id   = aws_instance.mongo-server.id
  allocation_id = aws_eip.mongo_server_eip.id
}
