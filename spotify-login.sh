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
# (client secret lives in the token file since 1.4.1; pre-1.4.1 devices may still have it in settings)
echo "Reading settings from Toon..."
SETTINGS_JSON=$($TOON "cat $SETTINGS 2>/dev/null")
TOKENS_JSON=$($TOON "cat $TOKEN_FILE 2>/dev/null")
CLIENT_ID=$( (echo "$TOKENS_JSON"; echo "$SETTINGS_JSON") | python3 -c "
import json,sys
raw=[l for l in sys.stdin if l.strip()]
for s in raw:
    try:
        d=json.loads(s)
        v=d.get('spotifyClientId','')
        if v: print(v); break
    except Exception: pass
" 2>/dev/null)
CLIENT_SECRET=$(echo "$TOKENS_JSON" | python3 -c "import json,sys; s=json.load(sys.stdin); print(s.get('spotifyClientSecret',''))" 2>/dev/null)
if [ -z "$CLIENT_SECRET" ]; then
    CLIENT_SECRET=$(echo "$SETTINGS_JSON" | python3 -c "import json,sys; s=json.load(sys.stdin); print(s.get('spotifyClientSecret',''))" 2>/dev/null)
fi

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

# Write client credentials + tokens to the dedicated token file (the ONLY place secrets/tokens are stored)
TOKENS_OUT=$(python3 -c "
import json, sys
print(json.dumps({
    'spotifyClientId': sys.argv[1],
    'spotifyClientSecret': sys.argv[2],
    'refresh_token': sys.argv[3],
    'access_token': sys.argv[4],
}))
" "$CLIENT_ID" "$CLIENT_SECRET" "$REFRESH_TOKEN" "$ACCESS_TOKEN")
printf '%s' "$TOKENS_OUT" | $TOON "cat > $TOKEN_FILE"
$TOON "chmod 600 $TOKEN_FILE" 2>/dev/null || true

# Update main settings file locally (Toon may not have python3) and push to Toon
# NOTE: never put spotifyClientSecret or tokens in the settings file (removed there in 1.4.1)
UPDATED_SETTINGS=$(echo "$SETTINGS_JSON" | python3 -c "
import json, sys
try:
    s = json.load(sys.stdin)
except Exception:
    s = {}
s['spotifyStatus'] = 'configured'
s['spotifyClientId'] = sys.argv[1]
s.pop('spotifyClientSecret', None)
s.pop('spotifyRefreshToken', None)
print(json.dumps(s))
" "$CLIENT_ID")
printf '%s' "$UPDATED_SETTINGS" | $TOON "cat > $SETTINGS"
echo "Settings updated."

echo "Restarting Toon app..."
$TOON "reboot" 2>/dev/null || true

echo ""
echo "Done! Spotify should be connected within 15 seconds of the app restarting."
