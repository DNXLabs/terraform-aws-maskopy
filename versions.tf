terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = ">= 3.26, < 4.0"
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
  }
}
