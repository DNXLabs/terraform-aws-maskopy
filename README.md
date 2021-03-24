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
    source = "git::https://github.com/DNXLabs/terraform-aws-maskopy.git?ref=0.1.1"

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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | >= 3.26, < 4.0 |
| null | 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | >= 3.26, < 4.0 |
| aws.source | >= 3.26, < 4.0 |
| aws.staging | >= 3.26, < 4.0 |
| null | 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| application\_name | The name for the maskopy application, this name should match part of the string with the invoker role name. | `string` | `"MASKOPY"` | no |
| build\_lambda\_layer | If true will build the lambda layer. Set to true only with local source module. | `bool` | `false` | no |
| cost\_center | All the temporary resources are tagged with the code. | `string` | `"MaskopyCost"` | no |
| create\_obfuscation\_scripts\_bucket | Create bucket to store obfuscation scripts. | `bool` | `true` | no |
| custom\_source\_kms\_key | Custom KMS key, used when variable `custom_source_kms_key_enabled` equals to true. | `string` | `""` | no |
| custom\_source\_kms\_key\_enabled | Only used when encrypt RDS in source account with another KMS key. Remember to add permissions to the existing key. | `bool` | `false` | no |
| ecs\_docker\_image | Docker image that ECS task will run with and will download the scripts from S3 obfuscation bucket. | `string` | `"dnxsolutions/postgres-maskopy"` | no |
| ecs\_fargate\_role\_name | ECS role name. | `string` | `"ECS_MASKOPY"` | no |
| enabled | If true, will deploy the maskopy solution. | `bool` | `true` | no |
| lambda\_role\_name | Lambda role name. | `string` | `"LAMBDA_MASKOPY"` | no |
| lambdas\_names | n/a | `list(string)` | <pre>[<br>  "00-AuthorizeUser",<br>  "01-UseExistingSnapshot",<br>  "02-CheckForSnapshotCompletion",<br>  "03-ShareSnapshots",<br>  "04-CopySharedDBSnapshots",<br>  "05-CheckForDestinationSnapshotCompletion",<br>  "06-RestoreDatabases",<br>  "07-CheckForRestoreCompletion",<br>  "08a-CreateFargate",<br>  "08b-CreateECS",<br>  "09-TakeSnapshot",<br>  "10-CheckFinalSnapshotAvailability",<br>  "11-CleanupAndTagging",<br>  "ErrorHandlingAndCleanup"<br>]</pre> | no |
| obfuscation\_scripts\_bucket\_name | Bucket to store the obfuscations scripts, they should be uploaded inside `/obfuscation` folder. | `string` | n/a | yes |
| rds\_staging\_subnet\_group\_name | Staging RDS option group name to deploy the transient database. | `string` | n/a | yes |
| sqs\_queue\_name | SNS queue name to send messages when step functions complete running. | `string` | `"maskopy_sqs_queue"` | no |
| staging\_rds\_default\_kms\_key\_id | KMS key that maskopy will use for the transient RDS. | `string` | n/a | yes |
| staging\_subnet\_ids | Subnets inside the staging VPC to deploy the lambdas and ECS tasks. | `list(string)` | n/a | yes |
| staging\_vpc\_id | VPC id for the staging account. | `string` | n/a | yes |
| step\_function\_state\_machine\_name | Name for the step functions state machine. | `string` | `"maskopy-state-machine"` | no |

## Outputs

No output.

<!--- END_TF_DOCS --->


## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-aws-maskopy/blob/master/LICENSE) for full details.