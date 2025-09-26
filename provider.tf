terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.61.0"
    }
  }
}

# Configure AWS provider:

provider "aws" {
  region  = "us-east-1"
  version = "3.61.0"
  profile = "tf-pave-user"
  # SECURITY FIX: Removed hardcoded credential structure
  # Use AWS CLI profiles, environment variables, or IAM roles instead
}