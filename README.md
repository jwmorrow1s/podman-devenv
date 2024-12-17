# Purpose
To enable running nix shells on a docker image

# Why?
I was annoyed by running nix on my corporate Mac and this was easier for me tbh.

# Pre-requisites
- You'll need podman. Alternatively you could use docker, but I haven't tested if this works. All the calls _should_ be the same.

# How?
- Ok, so this is not complicated or particularly intelligent.
- All this does is within the Dockerfile, the image copies the host machine's ./home directory onto an image with a nix base.
- The Dockerfile instructs the ./home/flake.nix to `develop` using whichever `buildInputs` are specified.
```
.
├── Dockerfile
├── README.md
├── common.mod.sh
├── home
│   ├── ca_cert.pem
│   └── flake.nix
└── run.sh
```

# Limitations
- It's an awkward way to use nix.
- Errors are painful to deal with because you're dealing with them within an image build and all the obtuse errors from nix itself.

# Configuration
- An optional ./conf.conf _can_ be provided with the following variables declarable. These have defaults:
```
TEMP_DEVSHELL_IMAGE_NAME='temp-devshell-image'
TEMP_DEVSHELL_CONTAINER_NAME='temp-devshell-container'
TEMP_DEVSHELL_OCI_PROG='podman'
```

# How to run?
```
>_: sh run.sh
```

## On Mac, if using a VPN:
- you're going to need to make the nix command aware of your SSL cert.
- note the line in the Dockerfile:
```
...
RUN NIX_SSL_CERT_FILE='/home/ca_cert.pem' \ # <- this here
	nix develop \
...
```
- you'll need to make sure that's a cert of _ALL_ of your certs in your keychain. 
- I accomplished this by appending all of my certs into a single file and putting it in the ./home directory using the following commands (from the project root):
```
>_: security export -t certs -f pemseq -k /Library/Keychains/System.keychain -o /tmp/certs-system.pem
>_: security export -t certs -f pemseq -k /System/Library/Keychains/SystemRootCertificates.keychain -o /tmp/certs-root.pem
>_: cat /tmp/certs-root.pem /tmp/certs-system.pem > /tmp/ca_cert.pem
>_: sudo mv /tmp/ca_cert.pem ./home/
```
