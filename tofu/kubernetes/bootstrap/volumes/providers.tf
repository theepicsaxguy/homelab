terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.36"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 1.12.0"
    }
  }
}
