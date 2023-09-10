provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source = "./modules/vpc"

  cidr_block       = "172.10.0.0/19"
  eks_cluster_name = "sungjunyoung"
  private_subnets  = ["172.10.0.0/22", "172.10.4.0/22"]
  public_subnets   = ["172.10.30.0/24", "172.10.31.0/24"]
}
