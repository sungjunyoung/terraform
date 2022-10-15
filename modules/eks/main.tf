module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.30.2"

  cluster_name    = var.cluster_name
  cluster_version = "1.23"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni    = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = var.instance_types
  }
  eks_managed_node_groups = {
    blue  = {}
    green = {
      min_size     = 1
      max_size     = var.worker_node_max_size
      desired_size = var.worker_node_desired_size

      instance_types = var.instance_types
      capacity_type  = "SPOT"
    }
  }
  node_security_group_additional_rules = {
    egress_all = {
      description      = "Allow all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_users            = [
    {
      userarn  = var.user_arn
      username = var.username
      groups   = ["system:masters"]
    },
  ]
}

data "aws_eks_cluster" "sungjunyoung" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "sungjunyoung" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.sungjunyoung.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.sungjunyoung.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.sungjunyoung.token
}