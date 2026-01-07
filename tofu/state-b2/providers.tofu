terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State and plan encryption using pbkdf2 + AES-GCM
  encryption {
    key_provider "pbkdf2" "encryption_passphrase" {
      passphrase = var.encryption_passphrase
    }
    method "aes_gcm" "encryption_method" {
      keys = key_provider.pbkdf2.encryption_passphrase
    }
    state {
      method   = method.aes_gcm.encryption_method
      enforced = true
    }
    plan {
      method   = method.aes_gcm.encryption_method
      enforced = true
    }
  }

  # Remote state backend - INITIALLY COMMENTED OUT
  # Uncomment after initial bucket creation to enable remote state
  #
  # backend "s3" {
  #   bucket     = var.bucket_name
  #   key        = var.state_key
  #   region     = var.b2.region
  #   endpoint   = var.b2.endpoint
  #   access_key = var.b2.access_key_id
  #   secret_key = var.b2.secret_access_key
  #
  #   # Required for B2 S3 compatibility
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   skip_requesting_account_id  = true
  #   use_path_style              = false
  # }
}

# AWS provider configured for Backblaze B2 S3-compatible API
provider "aws" {
  region     = var.b2.region
  access_key = var.b2.access_key_id
  secret_key = var.b2.secret_access_key

  # Override S3 endpoint to use Backblaze B2
  endpoints {
    s3 = var.b2.endpoint
  }

  # Skip AWS-specific validations
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}
