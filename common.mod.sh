#!/usr/bin/env bash

function create_podman_volume_ifnexist () {
  # shellcheck disable=SC2143
  [ ! "$(podman volume ls | grep 'nix-store')" ] && podman volume create nix-store
}

function remove_container () {
  # shellcheck disable=SC2143
  [ "$(podman ps | grep 'temp-container')" ] && podman stop temp-container
  # remove the container
  # shellcheck disable=SC2143
  [ "$(podman ps -a | grep 'temp-container')" ] && podman rm temp-container
}

function ephemeral_shell () {
	create_podman_volume_ifnexist
	remove_container 
	podman build -t my-image .
	# -d detached so that it doesn't take over the terminal
	# interactive allows input to STDIN
	# -t allocated a tty for interaction (like bash or whatever)
	podman run -dit -v nix-store:/nix --name temp-container my-image /bin/sh 
	# initialize nix configuration
	# then run nix develop on running shell
	podman exec -it temp-container /bin/sh -c '
	  mkdir -p "$HOME/.config/nix" && \
	  touch "$HOME/.config/nix/nix.conf" && \
	  echo "experimental-features = nix-command flakes" > "$HOME/.config/nix/nix.conf" && \
	  nix develop
	\ '
	podman exec -it temp-container /bin/sh
}

