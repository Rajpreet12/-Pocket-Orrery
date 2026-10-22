variable "project" {
  description = "Name prefix for every resource."
  type        = string
  default     = "pocket-orrery"
}

variable "region" {
  description = "AWS region for the API, database and bucket. CloudFront is global."
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email for the $ budget alert and API error alarm. Leave empty to skip both."
  type        = string
  default     = ""
}

variable "monthly_budget_usd" {
  description = "Monthly AWS budget that triggers an email at 80% actual and 100% forecast."
  type        = number
  default     = 5
}

variable "github_repo" {
  description = "GitHub repo allowed to deploy from main, as owner/name (e.g. Rajpreet12/pocket-orrery). Leave empty to skip CI access."
  type        = string
  default     = ""
}

variable "create_github_oidc_provider" {
  description = "Set false if this AWS account already has the token.actions.githubusercontent.com OIDC provider."
  type        = bool
  default     = true
}

variable "local_dev_origins" {
  description = "Extra browser origins allowed to call the API (the Docker and Kubernetes copies)."
  type        = list(string)
  default     = ["http://localhost:8080", "http://localhost:30080"]
}
