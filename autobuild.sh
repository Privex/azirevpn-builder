#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/.bash_colors"
: ${DKR_DIR="${DIR}/dkr"}
: ${OUTPUT_DIR="${DIR}/output"}

: ${WAIT_TIME=3}
: ${FORCE=0}
: ${AZIRE_SRC=""}
: ${AZIRE_DST=""}
: ${APT_REPO="se1.apt-cache.privex.io"}

[[ -f "${DIR}/.env" ]] && source "${DIR}/.env" || true
[[ -f "${PWD}/.env" ]] && source "${PWD}/.env" || true

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

if (( $# < 1 )) || [[ "$1" == "-h" || "$1" == "--help" ]]; then
    msg yellow "Usage:${RESET} $0 DISTRO [RELEASE]\n"
    msg bold cyan "Examples:"
    msg cyan "
    Build a DEB on a specific Distro + release:${RESET}

        $0 ubuntu bionic
        $0 ubuntu focal
        $0 ubuntu 21.04

        $0 debian buster
        $0 debian bullseye

    ${CYAN}Build a DEB for the latest DockerHub release of a distro:${RESET}
        
        $0 ubuntu

        $0 debian
    "
    exit 1
fi


SCANNED_ARGS=0
while (( $# > 0 )) && (( SCANNED_ARGS == 0 )); do

    case "$1" in
        '-n'|'-nw'|'--no-wait')
            msg bold magenta "\n [+++] Disabling WAIT TIME. Will not sleep before generating Dockerfile :)\n"
            WAIT_TIME=0
            shift; continue
            ;;
        '-w'|'-wt'|'--wait-time')
            msg bold magenta "\n [+++] Setting WAIT TIME to: $2 seconds\n"
            WAIT_TIME="$2"
            shift; shift; continue
            ;;
        '-f'|'-F'|'--force'|'--overwrite')
            msg bold magenta "\n [+++] Enabling FORCE - will overwrite existing Dockerfile's instead of skipping them :)\n"
            FORCE=1
            shift; continue
            ;;
        '-l'|'--local')
            AZIRE_SRC="azirevpn-0.5.0/"
            AZIRE_DST="/build/azirevpn-0.5.0/"
            msg bold magenta "\n [+++] Enabled LOCAL mode."
            msg bold magenta   " [+++] Set AZIRE_SRC='${AZIRE_SRC}' AZIRE_DST='${AZIRE_DST}'\n"
            shift; continue;
            ;;
        '--azreset'|'-azr')
            AZIRE_SRC="" AZIRE_DST=""
            msg bold magenta "\n [+++] Reset AZIRE_SRC and AZIRE_DST to blank."
            shift; continue;
            ;;
        *)
            SCANNED_ARGS=1
            ;;
    esac



    #if [[ "$1" == "-n" || "$1" == "-nw" || "$1" == "--no-wait" ]]; then
    #fi
    #if [[  
    #if [[ "$1" == "-f" || "$1" == "-F" || "$1" == "--force" || "$1" == "--overwrite"  ]]; then
    #fi
    #SCANNED_ARGS=1
done



: ${OS_NAME="$1"}

if (( $# > 1 )); then
    : ${RELEASE_NAME="$2"}
else
    : ${RELEASE_NAME=""}
fi

FULL_NAME="${OS_NAME}"

[[ -n "$RELEASE_NAME" ]] && FULL_NAME="${FULL_NAME}.${RELEASE_NAME}" || true

DISTRO_DIR="${OUTPUT_DIR}/${OS_NAME}"

[[ -n "$RELEASE_NAME" ]] && DISTRO_DIR="${DISTRO_DIR}/${RELEASE_NAME}" || DISTRO_DIR="${DISTRO_DIR}/latest"
[[ -n "$RELEASE_NAME" ]] && DKR_LABEL_FB="${OS_NAME}-${RELEASE_NAME}" || DKR_LABEL_FB="${OS_NAME}"

[[ -d "$DISTRO_DIR" ]] || mkdir -pv "$DISTRO_DIR"

DKR_FILE_FB="${DKR_DIR}/${OS_NAME}/Dockerfile"
[[ -n "$RELEASE_NAME" ]] && DKR_FILE_FB="${DKR_FILE_FB}.${RELEASE_NAME}" || true
: ${DKR_FILE="$DKR_FILE_FB"}

if ! [[ -f "$DKR_FILE" ]]; then
    msgerr yellow " [!!!] WARNING: Docker file '${DKR_FILE}' doesn't exist. Calling gendocker.sh to generate it..."
    ${DIR}/gendocker.sh -n "${OS_NAME}" "${RELEASE_NAME}"
    if ! [[ -f "$DKR_FILE" ]]; then
        msgerr bold red " [!!!] ERROR: Docker file '${DKR_FILE}' still doesn't exist after calling gendocker.sh to generate it...- cannot continue."
        exit 5
    fi
fi

: ${DKR_REPO="azirebuild"}
: ${DKR_LABEL="${DKR_LABEL_FB}"}
: ${DKR_IMG="${DKR_REPO}:${DKR_LABEL}"}

cd "$DIR"

msg bold cyan " >>> Building docker image ${DKR_IMG} from Dockerfile '${DKR_FILE}' using context: $DIR"

DK_ARGS=("-t" "$DKR_IMG" "-f" "$DKR_FILE")
[[ -n "$AZIRE_SRC" ]] && DK_ARGS+=("--build-arg" "AZIRE_SRC=${AZIRE_SRC}") || true
[[ -n "$AZIRE_DST" ]] && DK_ARGS+=("--build-arg" "AZIRE_DST=${AZIRE_DST}") || true
[[ -n "$APT_REPO" ]] && DK_ARGS+=("--build-arg" "APT_REPO=${APT_REPO}")    || true

docker build "${DK_ARGS[@]}" "$DIR"

errcheck "$?" "docker build -t $DKR_IMG -f $DKR_FILE $DIR" "Something went wrong while building the docker image"

msg bold green " +++ Successfully built docker image ${DKR_IMG} from Dockerfile '${DKR_FILE}' using context: $DIR \n\n"



: ${CT_NAME="azirebuilder"}

msg bold cyan " >>> Running docker image ${DKR_IMG} with name '${CT_NAME}', and volume '${DISTRO_DIR}:/output' \n"
docker run --rm --name "$CT_NAME" -v "${DISTRO_DIR}:/output" -it "$DKR_IMG"

errcheck "$?" "docker build -t $DKR_IMG -f $DKR_FILE $DIR" "Something went wrong while building the docker image"

msg bold cyan " +++ Successfully finished running docker image ${DKR_IMG} with name '${CT_NAME}', and volume '${DISTRO_DIR}:/output' \n"

