#!/bin/bash
set -e

# Configuration
REPO_OWNER="Yorion-io"
REPO_NAME="yorion_engine"
DEST_DIR="NepaliDaateMenuBar/Frameworks" # Directory where artifacts will be saved
VERSION_FILE="$DEST_DIR/bs_calendar_version.txt"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Run 'brew install jq' first."
    exit 1
fi

# Check for GITHUB_TOKEN
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    echo "Please set GITHUB_TOKEN to a Personal Access Token with 'repo' scope."
    exit 1
fi

echo -e "${BLUE}🔍 Checking for latest release from $REPO_OWNER/$REPO_NAME...${NC}"

# Fetch latest release info from GitHub API (including pre-releases)
LATEST_RELEASE_JSON=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases" | jq -r '.[0]')
LATEST_TAG=$(echo "$LATEST_RELEASE_JSON" | jq -r .tag_name)

if [ "$LATEST_TAG" == "null" ] || [ -z "$LATEST_TAG" ]; then
    echo "Error: Could not find latest release. Check your token and repo access."
    exit 1
fi

# Strip 'v' prefix if present
VERSION_NUM=${LATEST_TAG#v}

echo "Latest version: $VERSION_NUM (Tag: $LATEST_TAG)"

# Check local version
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    echo "Current local version: $CURRENT_VERSION"
    
    if [ "$CURRENT_VERSION" == "$VERSION_NUM" ]; then
        echo -e "${GREEN}✅ Already up to date!${NC}"
        exit 0
    fi
fi

echo -e "${BLUE}⬇️  Downloading version $VERSION_NUM...${NC}"

# Define the assets we need
ASSETS=("apple-assets-${VERSION_NUM}.tar.gz")

# Create destination directory
mkdir -p "$DEST_DIR"

for ASSET_NAME in "${ASSETS[@]}"; do
    echo -e "${BLUE}🔍 Locating $ASSET_NAME...${NC}"
    
    ASSET_ID=$(echo "$LATEST_RELEASE_JSON" | jq -r ".assets[] | select(.name == \"$ASSET_NAME\") | .id")

    if [ -z "$ASSET_ID" ] || [ "$ASSET_ID" == "null" ]; then
        echo "Error: Asset $ASSET_NAME not found in release $LATEST_TAG"
        exit 1
    fi

    # Download using API for private assets
    TEMP_FILE="$DEST_DIR/$ASSET_NAME"
    DOWNLOAD_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/assets/$ASSET_ID"

    echo -e "${BLUE}⬇️  Downloading $ASSET_NAME...${NC}"

    HTTP_CODE=$(curl -L -w "%{http_code}" -o "$TEMP_FILE" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/octet-stream" \
        "$DOWNLOAD_URL")

    if [ "$HTTP_CODE" != "200" ]; then
        echo "Error: Failed to download $ASSET_NAME (HTTP $HTTP_CODE)"
        rm -f "$TEMP_FILE"
        exit 1
    fi

    echo -e "${BLUE}📦 Extracting $ASSET_NAME...${NC}"
    tar -xzf "$TEMP_FILE" -C "$DEST_DIR"
    rm "$TEMP_FILE"
done

# Update version file
echo "$VERSION_NUM" > "$VERSION_FILE"

echo -e "${GREEN}✅ Update complete! Dependencies updated to version $VERSION_NUM${NC}"
echo -e "Files placed in: $DEST_DIR"
