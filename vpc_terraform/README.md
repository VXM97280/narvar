How to run terraform

setup your aws credentials on your local account 
`https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html`

Install terraform 
1. Install brew if using Mac
2. brew install terraform

Terraform commands to use:
Navigate to the terraform folder narvar > vpc_terraform
1. `AWS_PROFILE=narvar terraform init`
2. `AWS_PROFILE=narvar terraform plan`
3. `AWS_PROFILE=narvar terraform apply`