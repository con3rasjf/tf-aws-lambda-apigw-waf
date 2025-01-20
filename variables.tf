#Lambda function
variable "create_lambda" {
  type        = bool
  default     = false
  description = "whether to create lambda"
}

variable "function_name" {
  description = "The name of the lambda function"
  type        = string
}

variable "description" {
  description = "Description of what your Lambda Function does"
  type        = string
  default     = ""
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime"
  type        = number
  default     = 128
}

variable "runtime" {
  description = "Python version to configure in lambda"
  type        = string
  default     = ""
}

variable "function_env" {
  description = "A map that defines environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}


#API Gateway
variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "API Gateway created by Terraform with OpenAPI specification"
}

#WAF
variable "rate_limit" {
  description = "Maximum number of requests allowed per IP per 5-minute period"
  type        = number
  default     = 10
}
