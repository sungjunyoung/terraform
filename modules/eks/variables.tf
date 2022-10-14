variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "instance_types" {
  type = list(string)
}

variable "worker_node_max_size" {
  type = number
}

variable "worker_node_desired_size" {
  type = number
}

variable "user_arn" {
  type = string
}

variable "username" {
  type = string
}