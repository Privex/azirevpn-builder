#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/.bash_colors"
: ${DKR_DIR="${DIR}/dkr"}
: ${TPL_FILE="${DKR_DIR}/Dockerfile.base"}

: ${WAIT_TIME=3}
: ${FORCE=0}

if (( $# < 1 )) || [[ "$1" == "-h" || "$1" == "--help" ]]; then
    msg yellow "Usage:${RESET} $0 DISTRO [RELEASE]\n"
    msg bold cyan "Examples:"
    msg cyan "
    Generate the Dockerfile for a specific Distro + release:${RESET}

        $0 ubuntu bionic
        $0 ubuntu focal
        $0 ubuntu 21.04

        $0 debian buster
        $0 debian bullseye

    ${CYAN}Generate the Dockerfile for the latest DockerHub release of a distro:${RESET}
        
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

[[ -n "$RELEASE_NAME" ]] && FULL_NAME="${FULL_NAME}:${RELEASE_NAME}" || true

DISTRO_DIR="${DKR_DIR}/${OS_NAME}"

[[ -d "$DISTRO_DIR" ]] || mkdir -pv "$DISTRO_DIR"

: ${OUT_NAME=""}
if [[ -z "$OUT_NAME" ]]; then
    OUT_NAME="Dockerfile"
    [[ -n "$RELEASE_NAME" ]] && OUT_NAME="${OUT_NAME}.${RELEASE_NAME}"
fi

: ${OUT_FILE="${DISTRO_DIR}/${OUT_NAME}"}

msg bold magenta "

 >>> Prepared variables:"

msg magenta "
        Distro/OS Name:     $OS_NAME
         Distro Folder:     $DISTRO_DIR
               Release:     $RELEASE_NAME
             Full Name:     $FULL_NAME

           Output Name:     $OUT_NAME
           Output File:     $OUT_FILE

"

if [[ -f "$OUT_FILE" ]]; then
    if (( FORCE == 0 )); then
        msgerr bold red " [!!!] Output file '${OUT_FILE}' already exists! FORCE is disabled, so will not overwrite."
        msgerr bold red " [!!!] If you want to overwrite Dockerfile's if they already exist, pass '-f' or '--force'"
        msgerr bold red " [!!!] during the options (BEFORE distro / release)\n"
        exit 7
    else
        msgerr bold yellow " [!!!] Warning: Overwriting existing output file: $OUT_FILE \n"
    fi
fi

msg cyan  " >>> Generating output file (from base file: $TPL_FILE): $OUT_FILE \n"
(( WAIT_TIME )) && sleep $WAIT_TIME || true

sed -E "s#OS_REPLACE#${FULL_NAME}#" "$TPL_FILE" | tee "$OUT_FILE"


msg bold green "\n [+++] FINISHED +++\n"
