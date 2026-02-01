#!/bin/bash
# Scan nearby networks
system_profiler SPAirPortDataType 2>/dev/null | grep -E "(SSID|BSSID|Signal|Channel|PHY)" | head -100
