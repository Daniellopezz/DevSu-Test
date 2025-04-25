terraform {
  backend "azurerm" {
    resource_group_name  = "devsu-tfstate-rg"
    storage_account_name = "devsutfstate"
    container_name       = "tfstate"
    key                  = "devsu-demo.terraform.tfstate"
  }
}