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
  default     = "ubuntu-24.04"
  description = "Runner that built the image"
  validation {
    condition = contains(["ubuntu-24.04", "ubuntu-24.04-arm"], RUNNER)
    error_message = "Invalid value for 'RUNNER' variable"
  }
}

variable "VERSION" {
  type        = string
  default     = "29.2.knots20251110"
  description = "Version of Knots to build"
  validation {
    condition = contains([
      "27.1.knots20240801",
      "28.1.knots20250305",
      "29.1.knots20250903",
      "29.2.knots20251010",
      "29.2.knots20251110"
    ], VERSION)
    error_message = "Invalid value for 'VERSION' variable"
  }
}

group "default" {
  targets = ["knots", "miner"]
}

target "knots" {
  args = {
    KNOTS_VERSION = VERSION
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

target "bip110" {
  context = "bip110"
  cache-to = [{ type = "inline" }]
  cache-from = [
    {
      type = "registry"
      ref  = "ghcr.io/bcnbitcoinonly/bitcoin:v29.2.knots20251110-bip110-v0.1-${RUNNER}"
    }
  ]
  tags = ["ghcr.io/bcnbitcoinonly/bitcoin:v29.2.knots20251110-bip110-v0.1-${RUNNER}"]
}
