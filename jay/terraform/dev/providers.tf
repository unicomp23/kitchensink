provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment        = "dev"
      Project            = "kafka-poc"
      ManagedByTerraform = "True"
    }
  }

  assume_role {
    role_arn     = "arn:aws:iam::060795946368:role/terraform-role"
    session_name = "terraform"
  }
}