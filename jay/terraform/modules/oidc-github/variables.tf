variable "github_thumbprint_list" {
  description = "Thumbprint list of intermediary certificates for GitHub Actions SSL certificate"
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

variable "github_organization" {
  description = "GitHub Organization where GitHub Actions run"
  type        = string
}

variable "github_repository_role" {
  description = "Repository in which to set up OIDC authentication with AWS"
  type = map(
    object({
      repository                  = string
      iam_role_name               = string
      iam_source_policy_documents = list(string)
      iam_path                    = optional(string, "/gh_actions/")
    })
  )
}

variable "tags" {
  description = "Map of tags to be applied to all resources."
  type        = map(string)
  default     = {}
}
