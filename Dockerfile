FROM nixos/nix:latest

WORKDIR /home/
COPY home /home/

# RUN chown -R root:root /nix

RUN NIX_SSL_CERT_FILE='/home/ca_cert.pem' \ 
	nix develop \
	--extra-experimental-features "nix-command flakes" 
