#!/bin/bash
# Scan nearby networks
OUTPUT="wifi-scan-results.txt"
echo "WiFi Scan $(date)" > "$OUTPUT"
echo "========================" >> "$OUTPUT"
system_profiler SPAirPortDataType 2>/dev/null | grep -E "(SSID|BSSID|Signal|Channel|PHY)" | head -100 | tee -a "$OUTPUT"
echo ""
echo "Results saved to $OUTPUT"
