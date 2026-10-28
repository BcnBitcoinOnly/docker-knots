variable "CONTEXT" {
  type        = string
  default     = "cmake"
  description = "autotools up to v28.1.knots20250305, cmake after"
  validation {
    condition = contains(["autotools", "cmake"], CONTEXT)
    error_message = "Invalid value for 'CONTEXT' variable"
  }
}

variable "RUNNER" {
  type        = string
  default     = "ubuntu-26.04"
  description = "Runner that built the image"
  validation {
    condition = contains(["ubuntu-26.04", "ubuntu-26.04-arm"], RUNNER)
    error_message = "Invalid value for 'RUNNER' variable"
  }
}

variable "VERSION" {
  type        = string
  default     = "29.3.knots20260507"
  description = "Version of Knots to build"
  validation {
    condition = contains([
      "27.1.knots20240801",
      "28.1.knots20250305",
      "29.1.knots20250903",
      "29.2.knots20251010",
      "29.2.knots20251110",
      "29.3.knots20260210",
      "29.3.knots20260507"
    ], VERSION)
    error_message = "Invalid value for 'VERSION' variable"
  }
}

variable "PUBLIC_ALPINE_IMAGE" {
  type = string
  default = "sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a" # :3.24
}

group "default" {
  targets = ["knots", "miner"]
}

target "knots" {
  args = {
    KNOTS_VERSION = VERSION
    PUBLIC_ALPINE_IMAGE = PUBLIC_ALPINE_IMAGE
  }
  context = CONTEXT
  cache-to = [{ type = "inline" }]
  cache-from = [
    {
      type = "registry"
      ref  = "ghcr.io/bcnbitcoinonly/bitcoin:v${VERSION}-${RUNNER}"
    }
  ]
  tags = ["ghcr.io/bcnbitcoinonly/bitcoin:v${VERSION}-${RUNNER}"]
}

target "miner" {
  args = {
    KNOTS_VERSION = VERSION
    PUBLIC_ALPINE_IMAGE = PUBLIC_ALPINE_IMAGE
  }
  context = "cmake"
  cache-to = [{ type = "inline" }]
  cache-from = [
    {
      type = "registry"
      ref  = "1maa/bitcoin:signet-miner"
    }
  ]
  platforms = ["linux/amd64", "linux/arm64"]
  tags = ["1maa/bitcoin:signet-miner"]
  target = "signet-miner"
}
