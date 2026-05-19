#!/bin/bash
# Run this on your PC to connect Spotify to the Toon.
# Usage: bash spotify-login.sh

TOON_IP="192.168.10.68"
SSH_OPTS="-o HostKeyAlgorithms=+ssh-rsa -o StrictHostKeyChecking=no"
TOON="sshpass -p toon ssh $SSH_OPTS root@$TOON_IP"
TSCP="sshpass -p toon scp -O $SSH_OPTS"
SETTINGS="/mnt/data/tsc/sonos.userSettings.json"
TOKEN_FILE="/mnt/data/tsc/sonos.spotifyToken.json"

# Check dependencies
if ! command -v sshpass &>/dev/null; then
    echo "Install sshpass first:  sudo apt install sshpass"
    exit 1
fi

# Read existing credentials from Toon if available
echo "Reading settings from Toon..."
SETTINGS_JSON=$($TOON "cat $SETTINGS 2>/dev/null")
CLIENT_ID=$(echo "$SETTINGS_JSON" | python3 -c "import json,sys; s=json.load(sys.stdin); print(s.get('spotifyClientId',''))" 2>/dev/null)
CLIENT_SECRET=$(echo "$SETTINGS_JSON" | python3 -c "import json,sys; s=json.load(sys.stdin); print(s.get('spotifyClientSecret',''))" 2>/dev/null)

if [ -z "$CLIENT_ID" ]; then
    read -p "Spotify Client ID: " CLIENT_ID
fi
if [ -z "$CLIENT_SECRET" ]; then
    read -s -p "Spotify Client Secret: " CLIENT_SECRET
    echo
fi

# Build and show auth URL
AUTH_URL="https://accounts.spotify.com/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=https%3A%2F%2Fexample.com&scope=playlist-read-private%20playlist-read-collaborative"

echo ""
echo "===> Open this URL in your browser and log in with Spotify:"
echo ""
echo "  $AUTH_URL"
echo ""
echo "After authorizing, your browser redirects to example.com."
echo "Copy everything after 'code=' in the address bar."
echo ""
read -p "Paste the code here: " AUTH_CODE

if [ -z "$AUTH_CODE" ]; then
    echo "No code entered. Aborting."
    exit 1
fi

# Exchange code for tokens
echo ""
echo "Exchanging code for tokens..."
RESPONSE=$(curl -s -X POST https://accounts.spotify.com/api/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -u "${CLIENT_ID}:${CLIENT_SECRET}" \
    -d "grant_type=authorization_code&code=${AUTH_CODE}&redirect_uri=https://example.com")

REFRESH_TOKEN=$(echo "$RESPONSE" | python3 -c "import json,sys; r=json.load(sys.stdin); print(r.get('refresh_token',''))" 2>/dev/null)
ACCESS_TOKEN=$(echo "$RESPONSE" | python3 -c "import json,sys; r=json.load(sys.stdin); print(r.get('access_token',''))" 2>/dev/null)

if [ -z "$REFRESH_TOKEN" ]; then
    echo "ERROR: Token exchange failed. Spotify responded with:"
    echo "$RESPONSE"
    exit 1
fi

echo "Got tokens. Writing to Toon..."

# Write tokens to dedicated token file (survives settings resets)
$TOON "echo '{\"refresh_token\":\"'\"$REFRESH_TOKEN\"'\",\"access_token\":\"'\"$ACCESS_TOKEN\"'\"}' > $TOKEN_FILE"

# Update main settings file: set status + credentials
$TOON "python3 -c \"
import json
try:
    with open('$SETTINGS', 'r') as f:
        s = json.load(f)
except:
    s = {}
s['spotifyStatus'] = 'configured'
s['spotifyClientId'] = '$CLIENT_ID'
s['spotifyClientSecret'] = '$CLIENT_SECRET'
s['spotifyRefreshToken'] = '$REFRESH_TOKEN'
with open('$SETTINGS', 'w') as f:
    json.dump(s, f)
print('Settings updated.')
\""

echo "Restarting Toon app..."
$TOON "reboot" 2>/dev/null || true

echo ""
echo "Done! Spotify should be connected within 15 seconds of the app restarting."
