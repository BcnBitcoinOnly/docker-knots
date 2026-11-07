variable "RUNNER_ARCH" {
  type = string
  default = "X64"
  description = "The architecture of the runner executing the job"
  validation {
    condition = contains(["ARM64", "X64"], RUNNER_ARCH)
    error_message = "Invalid value for 'RUNNER_ARCH' variable"
  }
}

variable "VERSION" {
  type        = string
  default     = "29.3.knots20260507"
  description = "Version of Knots to build"
  validation {
    condition = contains([
      "29.1.knots20250903",
      "29.2.knots20251010",
      "29.2.knots20251110",
      "29.3.knots20260210",
      "29.3.knots20260507"
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
  context = "."
  cache-to = [{ type = "inline" }]
  cache-from = [
    {
      type = "registry"
      ref  = "ghcr.io/bcnbitcoinonly/bitcoin:v${VERSION}-${RUNNER_ARCH}"
    }
  ]
  tags = ["ghcr.io/bcnbitcoinonly/bitcoin:v${VERSION}-${RUNNER_ARCH}"]
}

target "miner" {
  args = {
    KNOTS_VERSION = VERSION
  }
  context = "."
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
