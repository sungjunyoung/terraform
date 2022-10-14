module "vpc" {
  source = "./modules/vpc"

  cidr_block       = "172.10.0.0/19"
  eks_cluster_name = "sungjunyoung"
  private_subnets  = ["172.10.0.0/22", "172.10.4.0/22"]
  public_subnets   = ["172.10.31.0/24"]
}

module "eks" {
  source = "./modules/eks"

  cluster_name             = "sungjunyoung"
  private_subnet_ids       = module.vpc.private_subnet_ids
  instance_types           = ["t3.small"]
  vpc_id                   = module.vpc.vpc_id
  worker_node_desired_size = 2
  worker_node_max_size     = 2
  user_arn                 = "arn:aws:iam::153178401710:user/sungjunyoung"
  username                 = "sungjunyoung"
}