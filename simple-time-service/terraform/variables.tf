variable "region" {
    default = "us-east-1"
}

variable "app_name" {
    default = "simple-time-service"
}

variable "container_port" {
    default = 5000
}

variable "image" {
    description = "Docker image URI (ECR)"
}

