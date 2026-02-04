# Mesh failover script - runs on repeaters
# Managed centrally from Main router
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
