module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.name_prefix}-vpc"
  cidr = "10.99.0.0/18"

  azs            = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnets = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
}
