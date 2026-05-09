module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.eks_cluster_name
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
      instance_types = [var.node_group_instance_type]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }
}

# Grant my user access to EKS cluster
resource "aws_eks_access_entry" "local_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::039612851322:user/odl_user_2214047"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "local_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.local_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
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
  name   = "${var.eks_cluster_name}-ecr-policy"
  policy = data.aws_iam_policy_document.ecr_policy.json
}

# Attach the ECR policy to the EKS node IAM role
resource "aws_iam_role_policy_attachment" "attach_ecr_policy" {
  role       = module.eks.eks_managed_node_groups["default"].iam_role_name
  policy_arn = aws_iam_policy.ecr_policy.arn
}
