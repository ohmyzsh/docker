# `ohmyzsh/zsh`

![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/ohmyzsh/zsh?sort=semver) ![Docker Pulls](https://img.shields.io/docker/pulls/ohmyzsh/zsh)

This image contains a Zsh distribution compiled from the
[`zsh-users/zsh`](https://github.com/zsh-users/zsh) repository, with a Zsh version
dependent on the tag of the image.

The image does not include Oh My Zsh. It includes the packages required to read
the installed Zsh documentation with commands such as `man zshall`.

Example:

- `ohmyzsh/zsh:5.8`: contains a Zsh distribution with version 5.8. Similarly,
  `ohmyzsh/zsh:4.3.9` contains Zsh 4.3.11, the oldest Zsh version published as a
  Docker image.

- `ohmyzsh/zsh:latest`: contains the latest stable Zsh version.

- `ohmyzsh/zsh:master`: contains the latest master version of Zsh.

Look at the published tags of the image to see which Zsh versions are available.
