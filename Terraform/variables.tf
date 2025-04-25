variable "location" {
  description = "Region donde se va a crear"
  type        = string
  default     = "eastus2"
}

variable "resource_prefix" {
  description = "Prefijo para todos los recursos"
  type        = string
  default     = "devsu-demo"
}

variable "environment" {
  description = "Entorno (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes a usar en AKS"
  type        = string
  default     = "1.24.9"
}

variable "node_count" {
  description = "Número inicial de nodos en el cluster AKS"
  type        = number
  default     = 2
}

variable "node_count_min" {
  description = "Número mínimo de nodos para autoscaling"
  type        = number
  default     = 1
}

variable "node_count_max" {
  description = "Número máximo de nodos para autoscaling"
  type        = number
  default     = 5
}

variable "node_size" {
  description = "Tamaño de las VMs para los nodos de AKS"
  type        = string
  default     = "Standard_B2s"
}

variable "create_acr" {
  description = "¿Crear Azure Container Registry?"
  type        = bool
  default     = true
}