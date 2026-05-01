#!/bin/bash
# List all repositories accessible to the GitHub token (owned or shared)

set -e

# Configuration
GITHUB_TOKEN="${GITHUB_TOKEN:-$GITHUB_API_TOKEN}"
OUTPUT_FILE="${OUTPUT_FILE:-github_repos.txt}"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN or GITHUB_API_TOKEN must be set"
    exit 1
fi

echo "Fetching all repositories accessible to this token..."

# Fetch all repos accessible to the token (includes shared repos)
# Using /user/repos includes repos the authenticated user can access
PAGE=1
> "$OUTPUT_FILE"

while true; do
    RESPONSE=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user/repos?per_page=100&page=${PAGE}&type=owner,collaborator,organization_member")
    
    # Check if we got results
    if echo "$RESPONSE" | grep -q '"full_name"'; then
        echo "$RESPONSE" | python3 -c "
import sys, json
repos = json.load(sys.stdin)
for repo in repos:
    print(repo['full_name'])
" >> "$OUTPUT_FILE"
    else
        break
    fi
    
    # Check if there are more pages (check Link header or empty response)
    if [ "$(echo "$RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")" -eq 0 ]; then
        break
    fi
    
    PAGE=$((PAGE + 1))
done

REPO_COUNT=$(wc -l < "$OUTPUT_FILE")
echo "Found $REPO_COUNT accessible repositories"
echo "Saved to: $OUTPUT_FILE"

# Display repo list
cat "$OUTPUT_FILE"
