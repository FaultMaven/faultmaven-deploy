#!/bin/bash
# Quick script to check where packages are located

echo "Checking package locations..."
echo ""

# Try organization
echo "=== Checking FaultMaven organization ==="
gh api /orgs/FaultMaven/packages?package_type=container 2>/dev/null | \
  jq -r '.[] | "\(.name): \(.visibility)"' || echo "Cannot access org packages (may need admin rights)"

echo ""

# Try user account
echo "=== Checking user account ==="
gh api /user/packages?package_type=container 2>/dev/null | \
  jq -r '.[] | select(.name | contains("fm-") or contains("faultmaven")) | "\(.name): \(.visibility) (owner: \(.owner.login))"' || echo "No packages found"

echo ""
echo "=== Direct URLs to check manually ==="
echo "Org packages: https://github.com/orgs/FaultMaven/packages"
echo "Your packages: https://github.com/$(gh api /user --jq .login)?tab=packages"
