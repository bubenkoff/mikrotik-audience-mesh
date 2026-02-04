#!/bin/bash
# Deploy mesh-failover script from Main to all repeaters
# Usage: ./deploy-mesh-failover.sh

MAIN="192.168.88.1"
REPEATERS="192.168.88.2 192.168.88.3 192.168.88.4"
USER="admin"

echo "=== Fetching current script from Main ==="
scp -o StrictHostKeyChecking=no ${USER}@${MAIN}:/mesh-failover.txt /tmp/mesh-failover.txt
cat /tmp/mesh-failover.txt

echo ""
echo "=== Deploying to repeaters ==="
for ip in $REPEATERS; do
  echo "--- $ip ---"
  if ping -c1 -W2 $ip &>/dev/null; then
    scp -o StrictHostKeyChecking=no /tmp/mesh-failover.txt ${USER}@${ip}:/mesh-failover.txt
    ssh -o StrictHostKeyChecking=no ${USER}@${ip} '/system script set mesh-failover source=[/file get mesh-failover.txt contents]; :put "OK"'
  else
    echo "SKIP: unreachable"
  fi
done

echo ""
echo "=== Done ==="
