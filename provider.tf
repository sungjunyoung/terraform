terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend s3 {
    bucket         = "sungjunyoung-tfstate"
    key            = "terraform/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "sungjunyoung-tflock"
  }
}
