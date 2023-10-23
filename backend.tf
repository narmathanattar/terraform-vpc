terraform {
  backend "s3" {
    bucket         = "my-test-bucket0906"  
    key            = "narmatha/terraform.tfstate"  
    region         = "ap-south-1"  
    encrypt        = true  
  }
}
