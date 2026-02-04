terraform { 
  required_providers { 
    aws = { 
      source  = "hashicorp/aws" 
      version = "~> 5.92" 
    } 
  } 

  required_version = ">= 1.2" 

  backend "s3" {
    bucket         = "tfstate-mayufstudy-learning"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }

}
