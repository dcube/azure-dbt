variable "current_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "spoke_name" {
  type = string
}

#####################
# App configuration
#####################

variable "app_configuration_sku" {
  description = "Sku de la ressource App Configuration."
  default     = "free"
}

####################
## Service bus #####
####################

variable "service_bus_sku_name" {
  description = "Sku de la ressource Service Bus."
  default     = "Basic"
}

#####################
# Container
#####################

variable "container_repository" {
  type = string
}

variable "container_doc_repository" {
  type = string
}

variable "container_image_tag" {
  type = string
}

variable "container_cpu" {
  type = number
}

variable "container_memory" {
  type = string
}
