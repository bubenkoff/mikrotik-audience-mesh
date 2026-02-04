:local repeaters {"192.168.88.2";"192.168.88.3";"192.168.88.4"}

:foreach ip in=$repeaters do={
  :do {
    :if ([/ping $ip count=1] > 0) do={
      :log info ("mesh-deploy: updating " . $ip)
      /tool fetch mode=ssh address=$ip user=admin src-path=mesh-failover.txt dst-path=mesh-failover.txt upload=yes
      :delay 2s
      :log info ("mesh-deploy: done " . $ip)
    } else={
      :log warning ("mesh-deploy: " . $ip . " not reachable")
    }
  } on-error={
    :log error ("mesh-deploy: failed " . $ip)
  }
}
