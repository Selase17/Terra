<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app_alb"></a> [app\_alb](#module\_app\_alb) | ./modules/alb | n/a |
| <a name="module_app_asg"></a> [app\_asg](#module\_app\_asg) | ./modules/ec2-asg | n/a |
| <a name="module_iam"></a> [iam](#module\_iam) | ./modules/iam | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | ./modules/rds | n/a |
| <a name="module_security_groups"></a> [security\_groups](#module\_security\_groups) | ./modules/security-groups | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |
| <a name="module_web_alb"></a> [web\_alb](#module\_web\_alb) | ./modules/alb | n/a |
| <a name="module_web_asg"></a> [web\_asg](#module\_web\_asg) | ./modules/ec2-asg | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.alb_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_elb_service_account.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/elb_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_ami_id"></a> [app\_ami\_id](#input\_app\_ami\_id) | AMI ID for app-tier EC2 instances. Leave empty to auto-resolve the latest Amazon Linux 2023 AMI for the configured region via SSM. | `string` | `""` | no |
| <a name="input_app_desired_capacity"></a> [app\_desired\_capacity](#input\_app\_desired\_capacity) | Desired instances in the app-tier ASG | `number` | `2` | no |
| <a name="input_app_instance_type"></a> [app\_instance\_type](#input\_app\_instance\_type) | EC2 instance type for the application tier | `string` | `"t3.micro"` | no |
| <a name="input_app_max_size"></a> [app\_max\_size](#input\_app\_max\_size) | Maximum instances in the app-tier ASG | `number` | `6` | no |
| <a name="input_app_min_size"></a> [app\_min\_size](#input\_app\_min\_size) | Minimum instances in the app-tier ASG | `number` | `2` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of Availability Zones — minimum 2 required for high availability | `list(string)` | <pre>[<br>  "eu-central-1a",<br>  "eu-central-1b"<br>]</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for all resources | `string` | `"eu-central-1"` | no |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | Initial allocated storage in GiB | `number` | `20` | no |
| <a name="input_db_backup_retention_period"></a> [db\_backup\_retention\_period](#input\_db\_backup\_retention\_period) | Days to retain automated DB backups | `number` | `7` | no |
| <a name="input_db_deletion_protection"></a> [db\_deletion\_protection](#input\_db\_deletion\_protection) | Enable RDS deletion protection | `bool` | `true` | no |
| <a name="input_db_engine"></a> [db\_engine](#input\_db\_engine) | Database engine: mysql or postgres | `string` | `"mysql"` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | Database engine version | `string` | `"8.0"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | RDS instance class | `string` | `"db.t3.small"` | no |
| <a name="input_db_max_allocated_storage"></a> [db\_max\_allocated\_storage](#input\_db\_max\_allocated\_storage) | Maximum storage for RDS autoscaling in GiB | `number` | `100` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the initial database | `string` | `"appdb"` | no |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | Master password — set via TF\_VAR\_db\_password env var; do not hardcode | `string` | n/a | yes |
| <a name="input_db_subnet_cidrs"></a> [db\_subnet\_cidrs](#input\_db\_subnet\_cidrs) | CIDR blocks for database subnets — one per AZ | `list(string)` | <pre>[<br>  "10.0.4.0/24",<br>  "10.0.5.0/24"<br>]</pre> | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Master username — set via TF\_VAR\_db\_username env var; do not hardcode | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment | `string` | `"production"` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | EC2 Key Pair name — leave empty to rely on SSM Session Manager instead | `string` | `""` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | CIDR blocks for private (app-tier) subnets — one per AZ | `list(string)` | <pre>[<br>  "10.0.2.0/24",<br>  "10.0.3.0/24"<br>]</pre> | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name — used as a prefix on every resource name | `string` | `"3tier-app"` | no |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | CIDR blocks for public (web-tier) subnets — one per AZ | `list(string)` | <pre>[<br>  "10.0.0.0/24",<br>  "10.0.1.0/24"<br>]</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_web_ami_id"></a> [web\_ami\_id](#input\_web\_ami\_id) | AMI ID for web-tier EC2 instances. Leave empty to auto-resolve the latest Amazon Linux 2023 AMI for the configured region via SSM. | `string` | `""` | no |
| <a name="input_web_desired_capacity"></a> [web\_desired\_capacity](#input\_web\_desired\_capacity) | Desired instances in the web-tier ASG | `number` | `2` | no |
| <a name="input_web_instance_type"></a> [web\_instance\_type](#input\_web\_instance\_type) | EC2 instance type for the web tier | `string` | `"t3.micro"` | no |
| <a name="input_web_max_size"></a> [web\_max\_size](#input\_web\_max\_size) | Maximum instances in the web-tier ASG | `number` | `6` | no |
| <a name="input_web_min_size"></a> [web\_min\_size](#input\_web\_min\_size) | Minimum instances in the web-tier ASG | `number` | `2` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_logs_bucket"></a> [alb\_logs\_bucket](#output\_alb\_logs\_bucket) | S3 bucket name for ALB access logs |
| <a name="output_app_alb_dns_name"></a> [app\_alb\_dns\_name](#output\_app\_alb\_dns\_name) | DNS name of the internal app Application Load Balancer |
| <a name="output_app_asg_name"></a> [app\_asg\_name](#output\_app\_asg\_name) | Name of the app-tier Auto Scaling Group |
| <a name="output_db_subnet_ids"></a> [db\_subnet\_ids](#output\_db\_subnet\_ids) | IDs of the database subnets |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of the private (app-tier) subnets |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of the public (web-tier) subnets |
| <a name="output_rds_endpoint"></a> [rds\_endpoint](#output\_rds\_endpoint) | RDS instance connection endpoint |
| <a name="output_rds_port"></a> [rds\_port](#output\_rds\_port) | RDS instance port |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
| <a name="output_web_alb_dns_name"></a> [web\_alb\_dns\_name](#output\_web\_alb\_dns\_name) | DNS name of the internet-facing web Application Load Balancer |
| <a name="output_web_asg_name"></a> [web\_asg\_name](#output\_web\_asg\_name) | Name of the web-tier Auto Scaling Group |
<!-- END_TF_DOCS -->