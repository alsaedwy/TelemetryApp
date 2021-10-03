# VPC for ECS
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "Telemetry-VPC"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  create_igw = "true"
  manage_default_security_group = "true"
  default_route_table_routes = [{"0.0.0.0/0": module.vpc.public_internet_gateway_route_id}]
  default_security_group_ingress = [
    {
      "description": "HTTP from the Internet"
      "from_port": "80"
      "to_port" : "80"
      "protocol": "tcp"
      "cidr_blocks": "0.0.0.0/0"
      "ipv6_cidr_blocks": "::/0"
    },
        {
      "description": "SSH from the Internet"
      "from_port": "22"
      "to_port" : "22"
      "protocol": "tcp"
      "cidr_blocks": "0.0.0.0/0"
      "ipv6_cidr_blocks": "::/0"
    }
  ]
default_security_group_egress = [
    {
      "from_port"        : "0"
      "to_port"          : "0"
      "protocol"         : "-1"
      "cidr_blocks"      : "0.0.0.0/0"
      "ipv6_cidr_blocks" : "::/0"
    }
  ]

}