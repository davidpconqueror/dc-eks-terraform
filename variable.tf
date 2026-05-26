variable "ssh_key_name" {
  description = "The name of the SSH key pair to use for instances"
  type        = string
  default     = "eks_handson_key" # Updated default key name string as well
}