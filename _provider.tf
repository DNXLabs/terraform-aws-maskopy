provider "null" {}

provider "aws" {
  alias = "source"
}

provider "aws" {
  alias = "staging"
}
