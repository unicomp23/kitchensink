terraform {
  required_version = ">= 1.9.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  backend "s3" {
    key            = "dev/terraform.tfstate"
    dynamodb_table = "cantina-dev-tfstate-lock-table"
    bucket         = "cantina-dev-tfstate-bucket"
    region         = "us-east-1"
    encrypt        = true
  }
}
