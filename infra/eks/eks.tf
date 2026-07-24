module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project}-eks"
  kubernetes_version = var.kubernetes_version

  # TODO: Replace with
  # endpoint_public_access_cidrs = ["<my IP>/32"]
  endpoint_public_access = true

  # Adds the identity running Terraform (the SSO role) as a cluster admin via an
  # EKS access entry, so kubectl is authorized immediately
  enable_cluster_creator_admin_permissions = true

  # before_compute = true installs networking/identity before nodes join
  addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = { before_compute = true }
  }

  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

  eks_managed_node_groups = {
    default = {
      ami_type       = var.node_ami_type
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      desired_size = var.node_desired_size
      max_size     = var.node_max_size

      # Reach nodes via Session Manager
      iam_role_additional_policies = {
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  tags = {
    Project = var.project
    Env     = var.environment
  }
}
