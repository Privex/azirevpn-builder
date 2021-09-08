#!/usr/bin/env bash

: ${REPO_FILE="/etc/apt/sources.list"}
: ${APT_REPO="se1.apt-cache.privex.io"}

REPLACE_REPO_LIST=(
    archive.ubuntu.com
    deb.debian.org
    http.kali.org
)

(( $# > 0 )) && APT_REPO="$1"
(( $# > 1 )) && REPO_FILE="$2"

echo -e " [>>>] Replacing repos in $REPO_FILE with new repo $APT_REPO \n"

for rp in "${REPLACE_REPO_LIST[@]}"; do
    echo "      -> Replacing repository '${rp}' with '${APT_REPO}' if found..."
    sed -Ei "s#${rp}#${APT_REPO}#g" "$REPO_FILE"
done

echo -e "\n [>>>] Repository file $REPO_FILE now contains: \n"

echo -e "\n ================================================== \n"
sed -E 's/#.*$//g' "$REPO_FILE" | tr -s '\n'
echo -e "\n ================================================== \n"

echo -e "\n [+++] Finished replacing repos in $REPO_FILE with new repo $APT_REPO :) \n"
exit 0

