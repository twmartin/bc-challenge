# bc-challenge [![Build Status](https://travis-ci.org/twmartin/bc-challenge.svg?branch=master)](https://travis-ci.org/twmartin/bc-challenge)

Nginx running in Docker on AWS ECS Fargate across multiple availability zones and fronted by an ALB with ACM providing the TLS certificate. AWS infrastructure creation orchestrated with Terraform. I have this set up to run from my own AWS environment and it is accessible to the public at https://bc-challenge.twmartin.codes.

## Setup Instructions

If you wish to stand this up in your own environment, run `terraform apply` while overriding the default Terraform vairables accordingly.
