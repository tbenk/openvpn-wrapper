# Manage multiple OpenVPN Client Configurations

## Expected Directory Structure:

```
   # $base/bin/vpn.sh
   # $base/config/<NAME1>/config.opvn
   # $base/config/<NAME2>/config.opvn
   # $base/config/<...>/config.opvn
   # $base/misc/screenrc
   # $base/pidfiles/<NAME1>
   # $base/pidfiles/<NAME2>
   # $base/pidfiles/<...>
```

## OpenVPN Config Requirements:

* vpn config must be located at $base/<NAME>/config.ovpn
* vpn config must contain "writepid $base/pidfiles/<NAME>"
* username/password auth only via auth-user-pass file

## Connect to VPN screen Session

```
   screen -r vpn
```
