variable "ZSH_VERSION" {
  default = "master"
}

variable "OMZ_VERSION" {
  default = "master"
}

variable "ZSH_BASE_IMAGE" {
  # Familiar form is required: BuildKit normalises a FROM ref before matching named context keys,
  # so a docker.io/-qualified value would silently skip the LINK_ZSH link and pull from Docker Hub.
  default = "ohmyzsh/zsh:latest"
}

# When true, ZSH_BASE_IMAGE is satisfied by the zsh target instead of being pulled
# from the registry, so pull requests validate Oh My Zsh against their own zsh build.
variable "LINK_ZSH" {
  default = "false"
}

variable "PLATFORMS" {
  default = "linux/amd64,linux/arm64"
}

target "zsh" {
  context   = "zsh"
  platforms = split(",", PLATFORMS)
  args = {
    ZSH_VERSION = ZSH_VERSION
  }
}

target "ohmyzsh" {
  context   = "ohmyzsh"
  platforms = split(",", PLATFORMS)
  args = {
    OMZ_VERSION    = OMZ_VERSION
    ZSH_BASE_IMAGE = ZSH_BASE_IMAGE
  }
  contexts = LINK_ZSH == "true" ? { (ZSH_BASE_IMAGE) = "target:zsh" } : {}
}
