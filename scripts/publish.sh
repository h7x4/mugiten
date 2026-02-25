#!/usr/bin/env bash

set -euo pipefail

declare -a COMMANDS=(
  curl
  git
)

for cmd in "${COMMANDS[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "$cmd could not be found" >&2
    exit 1
  fi
done

if [ -z "${GITEA_USER:-}" ]; then
    echo "GITEA_USER is not set" >&2
    exit 1
fi

if [ -z "${GITEA_TOKEN:-}" ]; then
    echo "GITEA_TOKEN is not set" >&2
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <version>" >&2
    exit 1
fi

declare -r VERSION="$1"

if [[ ! "$VERSION" =~ ^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$ ]]; then
    echo "$VERSION does not look like a valid version name"
    exit 1
fi

declare -r PACKAGE_API_ENDPOINT="https://git.pvv.ntnu.no/api/packages/mugiten/generic/mugiten/$VERSION/mugiten.apk"

declare -r PROJECT_ROOT="$(git rev-parse --show-toplevel)"
declare -r APK_PATH="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"

if [[ ! -f "$APK_PATH" ]]; then
    echo "$APK_PATH does not exist"
    exit 1
fi

if curl -X GET --silent --head --fail --user "$GITEA_USER:$GITEA_TOKEN" "$PACKAGE_API_ENDPOINT" >/dev/null; then
  echo "Version $VERSION seems to already exist"
  exit 1
else
  echo "Uploading APK for version $VERSION..."

  curl \
    -X PUT \
    --user "$GITEA_USER:$GITEA_TOKEN" \
    --progress-bar \
    --upload-file "$APK_PATH" \
    "$PACKAGE_API_ENDPOINT"
fi
