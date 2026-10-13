variable "cloudflare_api_token" {
  description = "Cloudflare API token with Tunnel Edit and DNS Edit permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "tunnels" {
  description = "Map of tunnel configurations"
  type = map(object({
    name   = string
    domain = string
    routes = list(object({
      hostname       = string
      path           = optional(string)
      service        = string
      origin_request = optional(map(any))
      access         = optional(bool, false)
    }))
  }))
  default = {}
}

variable "cloudflare_identity_provider_id" {
  description = "Cloudflare Identity Provider ID (leave empty to skip Access setup)"
  type        = string
  default     = ""
}
