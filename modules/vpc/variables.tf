variable "vpc_name" {
  type    = string
  default = "sungjunyoung"
}

variable "cidr_block" {
  type = string
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2b", "ap-northeast-2c"]
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "eks_cluster_name" {
  type = string
}
