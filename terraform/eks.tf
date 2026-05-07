module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  cluster_addons = {
    aws-ebs-csi-driver = {
      addon_version = "v1.28.0-eksbuild.1"
    }
  }

  eks_managed_node_groups = {
    default = {
      name           = "node-group-1"
      instance_types = [local.instance_type]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }
}

# IAM policy to allow EKS nodes to pull images from ECR
data "aws_iam_policy_document" "ecr_policy" {
  statement {
    actions = [
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetAuthorizationToken"
            ]
    resources = ["*"]
  }
}

# Create the IAM policy for ECR access
resource "aws_iam_policy" "ecr_policy" {
  name   = "${local.cluster_name}-ecr-policy"
  policy = data.aws_iam_policy_document.ecr_policy.json
}

# Attach the ECR policy to the EKS node IAM role
resource "aws_iam_role_policy_attachment" "attach_ecr_policy" {
  role       = module.eks.eks_managed_node_groups["default"].iam_role_name
  policy_arn = aws_iam_policy.ecr_policy.arn
}
