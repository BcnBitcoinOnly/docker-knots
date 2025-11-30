variable "CONTEXT" {
  type = string
  default = "cmake"
  description = "autotools up to v28.1.knots20250305, cmake after"
}

variable "RUNNER" {
  type = string
  default = "ubuntu-24.04"
  description = "Runner that built the image"
}

variable "VERSION" {
  type = string
  default = "29.2.knots20251110"
  description = "Version of Knots to build"
}

group "default" {
  targets = ["knots"]
}

target "knots" {
  args = {
    KNOTS_VERSION = "${VERSION}"
  }
  context = "${CONTEXT}"
  cache-to = [{type = "inline"}]
  cache-from = [{
    type = "registry"
    ref = "ghcr.io/bcnbitcoinonly/bitcoin:v${VERSION}-${RUNNER}"
  }]
  tags = ["ghcr.io/bcnbitcoinonly/bitcoin:v${VERSION}-${RUNNER}"]
}
