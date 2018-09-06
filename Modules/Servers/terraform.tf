/*variable "subscription_id" {
  description = "The Azure subscription ID"
  default = "113c4764-142e-4738-ae97-85bf6e509eb6"
}

variable "tenant_id" {
  description = "The Azure tenant ID"
   default = "c8cd0425-e7b7-4f3d-9215-7e5fa3f439e8"
}

variable "client_id" {
  description = "The Azure client ID"
   default = "e607356b-3ef4-4e4e-b134-ba5678eba330"
}
variable "secret_access_key" {
  description = "The Azure secret access key" 
   default = "tIGGnNGxUevgmq895/IPEFnbF5f+H9YS1Y4mZ0NpPfk="
}*/
variable "public_key" {
  description = "ssh public key"
}
variable "location" {
  description = "The location that the resources will run in (e.g. East US)"
}

variable "resource_group" {
  description = "The resource group name in Azure"
}
