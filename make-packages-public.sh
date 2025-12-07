#!/bin/bash
# Script to make all FaultMaven GHCR packages public
# Requires: GitHub Personal Access Token with 'write:packages' scope

set -e

echo "======================================"
echo "Make FaultMaven Packages Public"
echo "======================================"
echo ""

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "ERROR: GITHUB_TOKEN not set"
    echo ""
    echo "To create a token:"
    echo "1. Go to https://github.com/settings/tokens/new"
    echo "2. Give it a name: 'GHCR Package Admin'"
    echo "3. Select scopes: 'write:packages', 'read:packages', 'delete:packages'"
    echo "4. Generate token"
    echo "5. Export it: export GITHUB_TOKEN=ghp_xxxxx..."
    echo ""
    exit 1
fi

packages=(
    "fm-auth-service"
    "fm-session-service"
    "fm-case-service"
    "fm-knowledge-service"
    "fm-evidence-service"
    "fm-agent-service"
    "fm-api-gateway"
    "fm-job-worker"
    "faultmaven-dashboard"
)

echo "This will make the following packages PUBLIC:"
for pkg in "${packages[@]}"; do
    echo "  - $pkg"
done
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Making packages public..."
echo ""

success_count=0
fail_count=0

for pkg in "${packages[@]}"; do
    echo -n "Processing $pkg... "

    # Try to update visibility
    response=$(curl -s -w "\n%{http_code}" \
        -X PATCH \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/orgs/FaultMaven/packages/container/$pkg" \
        -d '{"visibility":"public"}')

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" = "200" ]; then
        echo "✅ SUCCESS"
        ((success_count++))
    else
        echo "❌ FAILED (HTTP $http_code)"
        echo "   Response: $body"
        ((fail_count++))
    fi
done

echo ""
echo "======================================"
echo "Summary:"
echo "  ✅ Success: $success_count"
echo "  ❌ Failed: $fail_count"
echo "======================================"

if [ $fail_count -gt 0 ]; then
    echo ""
    echo "Common reasons for failure:"
    echo "  - Token lacks 'write:packages' scope"
    echo "  - Not an organization admin/owner"
    echo "  - Package name mismatch"
    echo ""
    echo "Alternative: Update manually via GitHub UI"
    echo "  https://github.com/orgs/FaultMaven/packages"
    exit 1
fi

echo ""
echo "All packages are now PUBLIC! 🎉"
echo ""
echo "Verify at: https://github.com/orgs/FaultMaven/packages"
