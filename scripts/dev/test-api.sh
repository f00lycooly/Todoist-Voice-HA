#!/bin/bash
# Test API endpoints locally

set -e

echo "🧪 Testing Todoist Voice HA API"
echo "==============================="

API_URL="${API_URL:-http://localhost:8080}"

# Function to test endpoint
test_endpoint() {
    local method="$1"
    local endpoint="$2"
    local description="$3"
    local data="$4"
    
    echo "🔍 Testing: $description"
    echo "   $method $API_URL$endpoint"
    
    if [ "$method" = "GET" ]; then
        if curl -s -f "$API_URL$endpoint" > /dev/null; then
            echo "   ✅ Success"
        else
            echo "   ❌ Failed"
        fi
    elif [ "$method" = "POST" ]; then
        if curl -s -f -X POST -H "Content-Type: application/json" -d "$data" "$API_URL$endpoint" > /dev/null; then
            echo "   ✅ Success"
        else
            echo "   ❌ Failed"
        fi
    fi
    echo ""
}

# Check if server is running
echo "🔍 Checking if server is running at $API_URL"
if ! curl -s -f "$API_URL/health" > /dev/null; then
    echo "❌ Server not running at $API_URL"
    echo "Start with: ./scripts/dev/start-local-server.sh"
    exit 1
fi

echo "✅ Server is running!"
echo ""

# Test endpoints
test_endpoint "GET" "/health" "Health check"
test_endpoint "GET" "/ha-services/projects" "Get projects"
test_endpoint "POST" "/ha-services/find-projects" "Find projects" '{"query":"inbox","maxResults":5}'
test_endpoint "POST" "/ha-services/parse-voice-input" "Parse voice input" '{"text":"add buy milk to shopping list"}'
test_endpoint "POST" "/ha-services/validate-date" "Validate date" '{"dateInput":"tomorrow"}'

echo "🎉 API testing complete!"
echo ""
echo "💡 To see detailed responses:"
echo "   curl $API_URL/health | jq"
echo "   curl $API_URL/ha-services/projects | jq"
