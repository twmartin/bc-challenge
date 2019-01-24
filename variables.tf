variable "aws_region" {
  type = "string"
  default = "us-east-2"
}

variable "vpc" {
  type = "string"
  default = "vpc-07f2e5ff20c7e1f78"
}

variable "subnets" {
  type = "list"
  default = ["subnet-02ae0a30ba024518d", "subnet-02d2e87d860172704"]
}

variable "acm_certificate_arn" {
  type = "string"
  default = "arn:aws:acm:us-east-2:872676129263:certificate/9f1faa02-6609-450f-ab55-ae17fced7edc"
}

variable "route53_hosted_zone_id" {
  type = "string"
  default = "ZWQQSKOQD4SU1"
}

variable "route53_a_record_name" {
  type = "string"
  default = "bc-challenge.twmartin.codes."
}
