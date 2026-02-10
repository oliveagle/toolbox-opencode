#!/bin/bash
# Get the current Claude model being used

OUTPUT=$(claude --print --output-format json "What model are you using? Only respond with the model name, nothing else." 2>/dev/null)

# Extract model from modelUsage field (more accurate)
MODEL=$(echo "$OUTPUT" | jq -r '.modelUsage | keys[0]' 2>/dev/null)

if [ -n "$MODEL" ] && [ "$MODEL" != "null" ]; then
    echo "$MODEL"
else
    # Fallback to result field
    echo "$OUTPUT" | jq -r '.result' 2>/dev/null
fi
