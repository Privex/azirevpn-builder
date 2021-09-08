# AzireVPN Docker Package Builder

This project builds a DEB file for AzireVPN's client using Docker, so that it can be built  on the actual distro you want the DEB to work on.

Since the client isn't static, the binaries will only work on the same QT library version that they were built using, which is why
it requires per-distro DEB's instead of a universal DEB.

This builds [AzireVPN](https://azirevpn.com)'s [AZCLIENT](https://github.com/azirevpn/azclient) GUI VPN Client.

Using a source package, you can easily compile the client from source into a `.deb` package, regardless of
what debian-based distro you're running, or what architecture your system runs (amd64/i386/armhf/arm64/etc.).

This source package Docker build system was created by [Chris (Someguy123)](https://github.com/Someguy123) at [Privex Inc.](https://www.privex.io),
without any funding or guidance from AzireVPN - it was simply created to allow Privex to easily build DEB packages for their
VPN client to place on https://apt.privex.io (Privex's APT Repo).

License: X11 / MIT

**Basic usage**:

```sh
# Install Docker if you don't already have it.
apt update
apt install -y docker.io

# Clone the repo
git clone --recursive https://github.com/Privex/azirevpn-builder
cd azirevpn-builder

# Build a package for Ubuntu Focal 20.04
./autobuild.sh ubuntu focal

# Confirm it was built by checking the output folder for focal
ls -lh output/ubuntu/focal

# Build a package for Debian Buster (10), but use the local 'azirevpn-0.5.0/' folder
# instead of downloading a tarball during build
./autobuild.sh -l debian buster

# Use the APT repo 'apt-cache.privex.io' - usually you'd specify the domain or IP of an apt cache server,
# such as one running apt-cacher-ng, with the same repo folders as the distros (i.e. /debian points to debian
# repos, /ubuntu points to ubuntu repos etc.)
# If you're running apt-cacher-ng on the host machine, you can set this to 172.17.0.1 (or whatever your host's IP
# is on the docker subnet), or '172.17.0.1:3142' if you don't have a HTTP reverse proxy on port 80.
APT_REPO="apt-cache.privex.io" ./autobuild.sh ubuntu 21.04
```

**Manual Building**:

```sh
# If you want to manually build the Dockerfile's using 'docker build -f dkr/ubuntu/Dockerfile.focal',
# then you can use gendocker.sh to manually generate/update Dockerfile's for debian-based distros,
# like so:
./gendocker.sh ubuntu focal
# If you want to UPDATE an existing Dockerfile using the Dockerfile.base, then you can
# pass '-f' or '--force' to force it to overwrite existing files
./gendocker.sh -f ubuntu bionic

# Now you can build the Dockerfile manually:
docker build --build-arg 'APT_REPO=apt-cache.privex.io' -t azirebuild:focal -f dkr/ubuntu/Dockerfile.focal .

# Then run your built container, remember to pass a volume for output
docker run --rm -v "${PWD}/output/focal:/output" -it azirebuild:focal
```

If you want a Docker build to read the AzireVPN source package files from disk (must be in the build context - i.e. same folder as the script),
instead of from a remote Tarball, set `AZIRE_SRC` to the location of the source package folder relative to the project root,
and set `AZIRE_DST` to `/build/azirevpn-0.5.0/` so that the contents of the local folder are copied to the correct folder inside
of the container.

```sh
AZIRE_SRC="azirevpn-0.5.0/" AZIRE_DST="/build/azirevpn-0.5.0/" ./autobuild.sh ubuntu bionic
```


