# MikroTik Audience Mesh Setup

Home network mesh configuration using MikroTik Audience devices.

## Topology

```
[Main] ----cable---- [Repeater-1] ----cable---- [Repeater-3]
  |                      |                          |
  └──────── WiFi backup (wlan3) ────────────────────┘
```

| Role | IP | Hostname |
|------|-----|----------|
| Main (CAPsMAN controller) | 192.168.88.1 | Main |
| Repeater-1 | 192.168.88.2 | Repeater-1 |
| Repeater-3 | 192.168.88.4 | Repeater-3 |

RouterOS version: 7.21.2

## CAPsMAN Configuration (Main)

### Channels
| Name | Frequency | Band | Width | TX Power |
|------|-----------|------|-------|----------|
| 2hz | 2412 (ch1) | 2ghz-g/n | 20MHz | 7 dBm |
| 5hz | 5180 (ch36) | 5ghz-n/ac | 80MHz (Ceee) | 23 dBm |

### Band Steering
Signal difference: **10 dB** (5GHz stronger)

Recommended range: 6-10 dB
- < 5 dB: weak band steering
- 6-10 dB: optimal
- > 15 dB: risk for IoT devices

### Access List (band steering rules)
```
0: interface=*5ghz* signal-range=-80..120 action=accept
1-3: (similar for each 5GHz interface)
4: interface=*2ghz* signal-range=-75..120 action=accept (fallback)
5: signal-range=-120..-75 action=reject (weak signal)
```

## Mesh Failover

### How it works
- Primary connection: Ethernet (ether1) daisy chain
- Backup: WiFi via wlan3
- Bridge path-cost for wlan3 = 100 (higher priority for ether1)

### mesh-failover script (on repeaters)
```routeros
:local ethRunning [/interface get ether1 running]
:local wlanDisabled [/interface get wlan3 disabled]
:if ($ethRunning && !$wlanDisabled) do={
  /interface set wlan3 disabled=yes
  :log info "mesh-failover: ether1 up, wlan3 disabled"
}
:if (!$ethRunning && $wlanDisabled) do={
  /interface set wlan3 disabled=no
  :log info "mesh-failover: ether1 down, wlan3 enabled"
}
```

### Centralized Deployment (Main → Repeaters)

**On Main:**
- `/mesh-failover.txt` — script source
- `mesh-deploy` script — pushes via SFTP to all repeaters

```routeros
:local repeaters {"192.168.88.2";"192.168.88.3";"192.168.88.4"}
:local srcFile "mesh-failover.txt"
:foreach ip in=$repeaters do={
  :do {
    :if ([/ping $ip count=1] > 0) do={
      :log info ("mesh-deploy: uploading to " . $ip)
      /tool fetch mode=sftp address=$ip user=admin src-path=$srcFile dst-path=$srcFile upload=yes
      :log info ("mesh-deploy: done " . $ip)
    } else={
      :log warning ("mesh-deploy: " . $ip . " offline")
    }
  } on-error={
    :log error ("mesh-deploy: failed " . $ip)
  }
}
```

**On Repeaters:**
- `mesh-update` script — updates script from file
- Scheduler: daily + on startup

```routeros
:local srcFile "mesh-failover.txt"
:do {
  :local newSrc [/file get $srcFile contents]
  :local curSrc [/system script get mesh-failover source]
  :if ($newSrc != $curSrc) do={
    /system script set mesh-failover source=$newSrc
    :log info "mesh-update: updated mesh-failover script"
  }
} on-error={
  :log warning "mesh-update: no update file"
}
```

### SSH Keys
Main has SSH private key imported for user admin — allows passwordless SFTP to repeaters.

## Useful Commands

```bash
# Connect to routers
ssh admin@192.168.88.1  # Main
ssh admin@192.168.88.2  # Repeater-1
ssh admin@192.168.88.4  # Repeater-3

# Check CAPsMAN
/caps-man/channel/print
/caps-man/registration-table/print
/caps-man/access-list/print

# Check bridge
/interface/bridge/port/print

# Run script deployment
/system/script/run mesh-deploy

# WiFi scan from Mac (requires sudo)
sudo ./wifi-scan.sh
```

## Power Settings

| Parameter | Value |
|-----------|-------|
| 5GHz TX | 23 dBm |
| 2.4GHz TX | 7 dBm |
| Actual 5GHz | -47 dBm |
| Actual 2.4GHz | -57 dBm |
| Difference | 10 dB |
