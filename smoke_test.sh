#!/bin/bash
# FaultMaven E2E Smoke Test - Happy Path Validation
#
# This script validates the complete FaultMaven stack by executing a realistic
# user journey from health checks through AI-assisted troubleshooting.
#
# Usage:
#   ./smoke_test.sh [API_URL]
#
# Example:
#   ./smoke_test.sh http://localhost:8090

set -e

# Configuration
API_URL="${1:-http://localhost:8090}"
TEST_LOG="/tmp/faultmaven_smoke_test.log"
TIMESTAMP=$(date +%s)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_header() {
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}============================================${NC}"
}

print_test() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

test_pass() {
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓ PASS${NC} - $1"
}

test_fail() {
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    echo -e "${RED}✗ FAIL${NC} - $1"
    echo "  Details: $2"
}

# Start tests
print_header "🚀 FaultMaven E2E Smoke Test"
echo "API URL: $API_URL"
echo "Started: $(date)"
echo ""

# Phase 1: Health Checks
print_header "Phase 1: Health Checks"

# Test 1: Basic health
print_test "Basic health check"
RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    STATUS=$(echo "$BODY" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$STATUS" = "healthy" ]; then
        test_pass "Gateway is healthy"
    else
        test_fail "Basic health" "Unexpected status: $STATUS"
    fi
else
    test_fail "Basic health" "HTTP $HTTP_CODE"
fi

# Test 2: Liveness probe
print_test "Liveness probe"
RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/health/live")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Process is alive"
else
    test_fail "Liveness probe" "HTTP $HTTP_CODE"
fi

# Test 3: Readiness probe
print_test "Readiness probe"
RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/health/ready")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "503" ]; then
    READY=$(echo "$BODY" | grep -o '"ready":[^,}]*' | cut -d':' -f2)
    STATUS=$(echo "$BODY" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

    if [ "$READY" = "true" ]; then
        test_pass "Gateway ready (status: $STATUS)"
    else
        test_fail "Readiness probe" "Not ready - check component health"
    fi
else
    test_fail "Readiness probe" "HTTP $HTTP_CODE"
fi

# Phase 2: Case Management
print_header "Phase 2: Case Management"

# Test 4: Create case
print_test "Create test case"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/api/v1/cases" \
    -H "Content-Type: application/json" \
    -d '{
        "title": "Smoke Test Case",
        "description": "E2E test case created at '"$(date -Iseconds)"'",
        "user_id": "smoke_test_user"
    }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "201" ]; then
    CASE_ID=$(echo "$BODY" | grep -o '"case_id":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$CASE_ID" ]; then
        test_pass "Case created (ID: $CASE_ID)"
    else
        test_fail "Create case" "No case_id in response"
    fi
else
    test_fail "Create case" "HTTP $HTTP_CODE - $BODY"
fi

# Phase 3: Evidence Upload
print_header "Phase 3: Evidence Upload"

if [ -n "$CASE_ID" ]; then
    # Test 5: Upload evidence
    print_test "Upload evidence file"

    # Create test log file
    cat > "$TEST_LOG" << 'EOF'
2025-12-10 10:00:00 ERROR Application failed to start
2025-12-10 10:00:01 ERROR Connection refused: database unreachable
2025-12-10 10:00:02 WARN  Retrying connection (attempt 1/3)
2025-12-10 10:00:05 ERROR Connection timeout after 3 seconds
2025-12-10 10:00:06 ERROR Service startup aborted
EOF

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/api/v1/evidence" \
        -H "X-User-ID: smoke_test_user" \
        -F "file=@${TEST_LOG}" \
        -F "case_id=${CASE_ID}" \
        -F "evidence_type=log" \
        -F "description=Smoke test evidence file")

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | head -n -1)

    if [ "$HTTP_CODE" = "201" ]; then
        EVIDENCE_ID=$(echo "$BODY" | grep -o '"evidence_id":"[^"]*"' | cut -d'"' -f4)
        FILENAME=$(echo "$BODY" | grep -o '"filename":"[^"]*"' | cut -d'"' -f4)
        test_pass "Evidence uploaded (file: $FILENAME)"
    else
        test_fail "Upload evidence" "HTTP $HTTP_CODE"
    fi

    # Cleanup
    rm -f "$TEST_LOG"
else
    test_fail "Upload evidence" "Skipped - no case_id available"
fi

# Phase 4: AI Agent
print_header "Phase 4: AI Agent"

if [ -n "$CASE_ID" ]; then
    # Test 6: Query AI agent
    print_test "Query AI agent"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/api/v1/agent/chat/${CASE_ID}" \
        -H "Content-Type: application/json" \
        --max-time 60 \
        -d '{
            "message": "What does the error log indicate? Summarize the issue."
        }')

    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | head -n -1)

    if [ "$HTTP_CODE" = "200" ]; then
        # Check if response contains any content
        if echo "$BODY" | grep -q -E '"response"|"message"|"content"'; then
            test_pass "AI agent responded"
        else
            test_fail "AI agent query" "Empty response"
        fi
    else
        test_fail "AI agent query" "HTTP $HTTP_CODE"
    fi
else
    test_fail "AI agent query" "Skipped - no case_id available"
fi

# Phase 5: Knowledge Base
print_header "Phase 5: Knowledge Base"

# Test 7: Search knowledge base
print_test "Search knowledge base"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/api/v1/knowledge/search" \
    -H "Content-Type: application/json" \
    -d '{
        "query": "database connection error",
        "search_mode": "keyword",
        "limit": 5
    }')

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$BODY" | grep -q '"results"'; then
        # Count results
        RESULT_COUNT=$(echo "$BODY" | grep -o '"results":\[' | wc -l)
        test_pass "Knowledge search operational (may be empty in fresh install)"
    else
        test_fail "Knowledge search" "No 'results' field in response"
    fi
else
    test_fail "Knowledge search" "HTTP $HTTP_CODE"
fi

# Final Summary
print_header "Test Summary"

echo ""
echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    echo -e "${RED}❌ Some tests failed. Check logs for details.${NC}"
    exit 1
else
    echo -e "Tests Failed: ${GREEN}0${NC}"
    echo ""
    echo -e "${GREEN}🎉 All tests passed! FaultMaven is operational.${NC}"
    exit 0
fi
