#!/usr/bin/env bash

function evaluate_config (){
  # shellcheck disable=SC1091
  [ -f ./conf.conf ] && source ./conf.conf

  # set defaults
  [ ! "$TEMP_DEVSHELL_CONTAINER_NAME" ] && TEMP_DEVSHELL_CONTAINER_NAME='temp-devshell-container'
  [ ! "$TEMP_DEVSHELL_IMAGE_NAME" ]     && TEMP_DEVSHELL_IMAGE_NAME='temp-devshell-image'
  [ ! "$TEMP_DEVSHELL_OCI_PROG" ]       && TEMP_DEVSHELL_OCI_PROG='podman'

  # shellcheck disable=SC2235
  if ! ([ "$TEMP_DEVSHELL_OCI_PROG" = 'podman' ] || [  "$TEMP_DEVSHELL_OCI_PROG" = 'docker' ]); then
    printf '[FATAL] the only OCI programs supported are docker or podman. You specified: %s \n' "$TEMP_DEVSHELL_OCI_PROG"
    exit 1
  fi
}

function remove_container () {
  # stop the container, if running
  # shellcheck disable=SC2143
  [ "$($TEMP_DEVSHELL_OCI_PROG ps | grep "$TEMP_DEVSHELL_CONTAINER_NAME")" ] && "$TEMP_DEVSHELL_OCI_PROG" stop "$TEMP_DEVSHELL_CONTAINER_NAME"
  # remove the container
  # shellcheck disable=SC2143
  [ "$($TEMP_DEVSHELL_OCI_PROG ps -a | grep "$TEMP_DEVSHELL_CONTAINER_NAME")" ] && "$TEMP_DEVSHELL_OCI_PROG" rm "$TEMP_DEVSHELL_CONTAINER_NAME"
}

function build_base_image () {
  "$TEMP_DEVSHELL_OCI_PROG" build -t "$TEMP_DEVSHELL_IMAGE_NAME" .
}

function run_container_detached_interactive_tty () {
  # -d detached so that it doesn't take over the terminal
  # interactive allows input to STDIN
  # -t allocated a tty for interaction (like bash or whatever)
  "$TEMP_DEVSHELL_OCI_PROG" run -dit --name "$TEMP_DEVSHELL_CONTAINER_NAME" "$TEMP_DEVSHELL_IMAGE_NAME" /bin/sh 
}

function initialize_nix_env_on_container () {
    # initialize nix configuration
    # then run nix develop on running shell
    # shellcheck disable=SC2016
    "$TEMP_DEVSHELL_OCI_PROG" exec -it "$TEMP_DEVSHELL_CONTAINER_NAME" /bin/sh -c '
      mkdir -p "$HOME/.config/nix" && \
      touch "$HOME/.config/nix/nix.conf" && \
      echo "experimental-features = nix-command flakes" > "$HOME/.config/nix/nix.conf" && \
      nix develop
    \ '
}

function attach_sh_session_to_running_nix_container () {
  "$TEMP_DEVSHELL_OCI_PROG" exec -it "$TEMP_DEVSHELL_CONTAINER_NAME" /bin/sh
}

function run_ephemeral_shell () {
	evaluate_config
	remove_container 
	build_base_image
	run_container_detached_interactive_tty
	initialize_nix_env_on_container
	attach_sh_session_to_running_nix_container
}

