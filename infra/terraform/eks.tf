module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Allow laptop + Jenkins to reach EKS API server
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  #######################################################################
  # EKS Access Entries (2024–2025 RBAC Model)
  # These give IAM users full kubectl cluster-admin access
  #######################################################################
  access_entries = {
    
    cicd_user_access = {
      principal_arn = "arn:aws:iam::447407244516:user/cicd-user"
      type          = "STANDARD"

      # Must be empty (AWS forbids system:* groups)
      kubernetes_groups = []

      # Full cluster-admin privileges
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    jenkins_ci_access = {
      principal_arn = "arn:aws:iam::447407244516:user/jenkins-ci"
      type          = "STANDARD"

      # Must be empty (no system: groups allowed)
      kubernetes_groups = []

      # Full cluster-admin privileges for Jenkins user
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  #######################################################################
  # Node Group
  #######################################################################
  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.small"]
      capacity_type  = "ON_DEMAND"
    }
  }

  #######################################################################
  # Tags
  #######################################################################
  tags = {
    Project = var.project_name
  }
}
