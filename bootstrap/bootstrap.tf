provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "sungjunyoung-tfstate"
}

resource "aws_dynamodb_table" "tflock" {
  name         = "sungjunyoung-tflock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}