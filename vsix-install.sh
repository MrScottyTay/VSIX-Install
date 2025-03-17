#!/bin/bash

# Check for required dependencies
for cmd in curl jq unzip grep sed cut mktemp rm mkdir; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is required but not installed. Please install it and try again."
    exit 1
  fi
done

# Flags
DOWNLOAD_ONLY=false
KEEP=false
FORCE=false
DIR="${HOME}/Downloads"
ARGUMENT=

# Handle single letter flags
while getopts "dfk" opt; do
  case $opt in
    d) DOWNLOAD_ONLY=true ;;
    k) KEEP=true ;;
    f) FORCE=true ;;
    *)
      echo "Usage: $0 [-d] [-k] [-f] <extension_name_or_url>"
      exit 1
      ;;
  esac
done

# Remove the flags part from the arguments
shift $((OPTIND - 1))

# Handle long options and find the argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir=*)
      DIR="${1#--dir=}"
      shift
      ;;
    *)
      # If it's not a flag, assume it's the extension name/URL
      ARGUMENT="$1"
      shift
      ;;
  esac
done

# Check if an argument is provided
if [ -z "$ARGUMENT" ]; then
  echo "Usage: $0 [-d] [-k] [-f] <VS Marketplace URL or Extension Name> [--dir=path/to/vsix-downloads-folder]"
  exit 1
fi

# ---

# VS Code version detection
detect_vs_code_variant() {
  if command -v codium &> /dev/null; then
    echo "codium"
  elif command -v code &> /dev/null; then
    echo "code"
  elif command -v code-oss &> /dev/null; then
    echo "code-oss"
  else
    echo "No VS Code variant detected. Please install one." >&2
    exit 1
  fi
}

VS_CODE_CMD=$(detect_vs_code_variant)

# ---

# Function to extract publisher and extension from a URL
extract_from_url() {
  local url="${1}"
  local publisher=$(echo "$url" | sed -n 's/.*itemName=\([^&]*\).*/\1/p' | cut -d'.' -f1)
  local extension=$(echo "$url" | sed -n 's/.*itemName=\([^&]*\).*/\1/p' | cut -d'.' -f2)
  echo "$publisher $extension"
}

# Function to handle the case where only extension name is provided
extract_from_extension_name() {
  local extension_name="${1}"
  local publisher=$(echo "$extension_name" | cut -d'.' -f1)
  local extension=$(echo "$extension_name" | cut -d'.' -f2)
  echo "$publisher $extension"
}

# ---

# Function to check if the extension is already installed
check_if_installed() {
  local extension="${1}"

  # Capture the output of grep (whether the extension is installed or not)
  local grep_output=$($VS_CODE_CMD --list-extensions | grep -i "$extension")

  # Check if the output of grep is non-empty
  if [ -n "$grep_output" ]; then
    echo "Extension $extension is already installed."
    return 1  # Return 1 to indicate the extension is already installed
  else
    echo "Extension $extension is not installed."
    return 0  # Return 0 to indicate the extension is not installed
  fi
}

# ---

get_dependencies() {
  local extension_name="${1}"
  local vsix_file="${2}"

  # Extract the VSIX file to inspect its contents
  local temp_dir=$(mktemp -d)
  unzip -q "${vsix_file}" -d "${temp_dir}"

  # Check if the package.json exists
  local package_json="${temp_dir}/extension/package.json"

  if [ -f "${package_json}" ]; then
    # Extract the dependencies using jq and format them as a space-separated list
    local dependencies=$(jq -r 'try .extensionDependencies[]' "${package_json}")

    if [ -n "${dependencies}" ]; then
      echo -e "Dependencies found for '${extension_name}':"
      for dep in $dependencies; do
        printf "\t%s\n" "${dep}"
      done
      echo ""

      # Recurse over each dependency and download them before continuing
      for dep in $dependencies; do
        download "${dep}"
      done
    fi
  else
    echo "WARNING: package.json not found in the extension. Something maybe wrong with the downloaded extension but we'll continue anyway.\n"
  fi

  # Clean up temporary directory
  rm -rf "${temp_dir}"
}

VSIX_FILES=()

# Function to download an extension
download() {
  local input_value="${1}"
  local publisher
  local extension

  if [[ "${input_value}" == http* ]]; then
    extracted=$(extract_from_url "${input_value}")
  else
    extracted=$(extract_from_extension_name "${input_value}")
  fi

  IFS=' ' read -r publisher extension <<< "$extracted"

  $FORCE || (! check_if_installed "${publisher}.${extension}" && return 1)

  local vsix_url="https://${publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/${publisher}/extension/${extension}/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

  # Define the output filename for the VSIX file
  local output_file="${DIR}/${extension}_latest.vsix"
  mkdir -p "$DIR"

  # Download the VSIX file using curl to the Downloads folder
  echo -e "Downloading latest version of '${publisher}.${extension}'\nto '${output_file}'..."

  curl --progress-bar -L "${vsix_url}" -o "${output_file}" \
    || { echo "Download failed"; exit 1; }

  echo ""

  get_dependencies "${publisher}.${extension}" "${output_file}"

  # will be ordered by last dependency in the chain to the initial requested VSIX file
  VSIX_FILES+=("${output_file}") 
}

# Function to install the VSIX file
install() {
  # Install the VSIX files using vs code variant
  for vsix in "${VSIX_FILES[@]}"; do
    $VS_CODE_CMD --install-extension "$vsix"
  done

  echo ""

  if ! $KEEP; then
    # Delete the downloaded VSIX file after installation
    rm -- "${VSIX_FILES[@]}"
    echo -e "VSIX files in '${DIR}' deleted.\n"
  fi
}

echo -e "\nVS Code Variant: ${VS_CODE_CMD}\n"

# Start by downloading and handling the extension
download "${ARGUMENT}"
$DOWNLOAD_ONLY || install
echo -e "Complete\n"