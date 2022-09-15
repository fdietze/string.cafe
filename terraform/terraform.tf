terraform {
  backend "s3" {
    encrypt        = true
    region         = "eu-central-1"
    key            = "app.tfstate"
    bucket         = "string-cafe-terraform-state"
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
}
