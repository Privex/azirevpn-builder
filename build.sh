#!/usr/bin/env bash

: ${INSTALL_DEPS=0}
: ${BUILD_PKG=1}
: ${INSTALL_PKG=1}
: ${OUT_DIR="/output"}

errcheck() {
    local erret="$1" segment="NOT SPECIFIED" note=""
    (( $# > 1 )) && segment="$2"
    (( $# > 2 )) && note="$3"
    
    if (( erret )); then
        >&2 echo -e "\n [!!!] ERROR: Non-zero return code (${erret}) detected at segment: $segment"
        [[ -n "$note" ]] && >&2 echo -e " [!!!] NOTE: $note"
        >&2 echo ""
        exit $erret
    fi
    return 0
}


if (( INSTALL_DEPS )); then
    echo " >>> Installing dependencies using make install-deps"
    make install-deps
    errcheck "$?" "make install-deps" "Something went wrong while installing dependencies"
fi


if (( BUILD_PKG )); then
    echo " >>> Building DEB package using: make build-deb"
    make build-deb
    errcheck "$?" "make build-deb" "Something went wrong while building the DEB file."
    echo " >>> Copying 'azirevpn_*' to '${OUT_DIR}' ..."
    cp -v ../azirevpn_* "${OUT_DIR%/}/"
fi


if (( INSTALL_PKG )); then
    echo " >>> Installing DEB package using: make install-deb"
    make install-deb
    errcheck "$?" "make install-deb" "Something went wrong while installing the package from the DEB file."
fi


