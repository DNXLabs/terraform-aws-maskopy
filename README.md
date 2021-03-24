# terraform-aws-maskopy

[![Lint Status](https://github.com/DNXLabs/terraform-aws-maskopy/workflows/Lint/badge.svg)](https://github.com/DNXLabs/terraform-aws-maskopy/actions)
[![LICENSE](https://img.shields.io/github/license/DNXLabs/terraform-aws-maskopy)](https://github.com/DNXLabs/terraform-aws-maskopy/blob/master/LICENSE)

<img src="./docs/images/maskopy-banner.png" alt="drawing" width="400px"/>


## Overview:

Maskopy solution is to Copy and Obfuscate Production Data to Target Environments in AWS.
It uses AWS Serverless services, Step functions, Lambda and Fargate.


## Features:

### Simplified Copy and Obfuscation
Maskopy copies and provides ability to run obfuscation on production data across AWS accounts. Any sensitive information in the production data is obfuscated in a transient instance. The final obfuscated snapshot is shared in the user-specified environments.

### Self-Service and End-To-End Automation
Maskopy is a self-serviced solution that allows users to get production data without involving multiple teams. It is fully automated and is implemented to easily plug into CI/CD pipelines and other automation solutions through SNS or SQS.

### Secure Design
Maskopy has security controls such as access management via IAM roles, authorization on the caller identity, network access to transient resources controlled through security groups. Bring your own container with third party tools for obfuscation algorithms.

### Bring Your Own Obfuscation Container
Maskopy is a obfuscation tool agnostic solution. Teams can leverage any encryption tools or obfuscation frameworks based on their needs and bake those into a docker container. Bring the container to Maskopy solution  to run data obfuscation


## Usage

```hcl
module "maskopy" {
    source = "git::https://github.com/DNXLabs/terraform-aws-maskopy.git?ref=0.1.0"

    enabled = true

    providers = {
        aws.source  = aws.prod
        aws.staging = aws.nonprod
    }

    staging_vpc_id                 = data.aws_vpc.selected.id
    staging_subnet_ids             = data.aws_subnet_ids.staging_subnet_ids.ids
    staging_rds_default_kms_key_id = ""

    rds_staging_subnet_group_name = ""

    obfuscation_scripts_bucket_name = ""
}
```

## Documentation
- [Getting Started](docs/quickstart.md)
- [AWS Setup](docs/aws-setup.md)
- [Configurations](docs/configurations.md)


<!--- BEGIN_TF_DOCS --->

<!--- END_TF_DOCS --->


## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-aws-maskopy/blob/master/LICENSE) for full details.