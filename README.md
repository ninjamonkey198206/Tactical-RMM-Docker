# Tactical-RMM-Docker

###
## [Docker T-RMM Setup](#docker-t-rmm-setup-1)
###

###
## Docker T-RMM Setup
###
1) In env file change GATEWAY, SUBNET, and IP variables for the various networks and containers, API, APP, and MESH URL variables to suit environment. Edit remaining env to suit.

2) If running HAProxy on same system as docker containers, set http and https exp port variables to 127.0.1.1:port

3) Keep NATS exp port variable as 4222 and ensure firewall access. This requires a TCP only reverse proxy, and is not http traffic, so it cannot be routed through HAProxy while routing the rest through it until configuration quirks are ironed out.

4) If running IPTables firewall in Drop all by default with HAProxy on the same system, make sure to add the following:
```text
# This ensures communication because HAProxy and Docker don't play nice with Drop all by default
-A INPUT -i trmmproxy -p tcp -m multiport --sports 4443,8080 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
-A INPUT -i trmmproxy -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A OUTPUT -o trmmproxy -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -o trmmnats -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
```


# First Run:

1) Bring up stack once, then immediately stop the stack.

2) Copy valid fullchain cert and private key to "/path/to/docker/volumes/name_of_stack_data/_data/certs/" as fullchain.pem and privkey.pem respectively.

3) Start stack, verify access after init complete.

4) Log into mesh.example.com and configure 2fa, as well as client remote access settings for notification, permission, etc.


# T-RMM HAProxy config: 

Requires HAProxy 2.4+

Ubuntu/Debian:

1) Add RMM, API, and Mesh sites to /etc/hosts
```text
127.0.1.1 api-tactical.example.com api-tactical
127.0.1.1 rmm-tactical.example.com rmm-tactical
127.0.1.1 mesh-tactical.example.com mesh-tactical
```

5) Make sure firewall rules are in place, then edit HAProxy config.
  Example for T-RMM, assumes existing shared http and https frontends, SSL offloading, and http to https redirect already in place and working, edit urls and exp ports to suit environment:
  
  If not already present, add to both http and https shared frontends
```text
option                          forwardfor
http-request add-header         X-Real-IP %[src]
```
  Add http to https redirects for Mesh, RMM, and API in shared http frontend
```text
acl                     rmm     var(txn.txnhost) -m str -i rmm-tactical.example.com
acl                     api     var(txn.txnhost) -m str -i api-tactical.example.com
acl                     mesh    var(txn.txnhost) -m str -i mesh-tactical.example.com
http-request redirect scheme https  if  rmm
http-request redirect scheme https  if  api
http-request redirect scheme https  if  mesh
```
  Add https frontend Mesh, RMM, and API entries
```text
acl                     rmm     var(txn.txnhost) -m str -i rmm-tactical.example.com
acl                     api     var(txn.txnhost) -m str -i api-tactical.example.com
acl                     is_websocket    hdr(Upgrade) -i WebSocket
acl                     mesh    var(txn.txnhost) -m str -i mesh-tactical.example.com
use_backend rmm-tactical.example.com_ipvANY  if  rmm
use_backend rmm-tactical.example.com_ipvANY  if  api
use_backend mesh-tactical.example.com-websocket_ipvANY  if  is_websocket mesh
use_backend mesh-tactical.example.com_ipvANY  if  mesh
```
  Add backends
```text
backend rmm-tactical.example.com_ipvANY
        mode                    http
        log                     global
        timeout connect         30000
        timeout server          30000
        retries                 3
        server                  rmm 127.0.1.1:4443 ssl  verify none


backend mesh-tactical.example.com-websocket_ipvANY
        mode                    http
        log                     global
        timeout connect         3000
        timeout server          3000
        retries                 3
        timeout tunnel          3600000
        http-request add-header X-Forwarded-Host %[req.hdr(Host)]
        http-request add-header X-Forwarded-Proto https
        server                  mesh-websocket 127.0.1.1:4443 ssl  verify none


backend mesh-tactical.example.com_ipvANY
        mode                    http
        log                     global
        timeout connect         15000
        timeout server          15000
        retries                 3
        timeout tunnel          15000
        http-request add-header X-Forwarded-Host %[req.hdr(Host)]
        http-request add-header X-Forwarded-Proto https
        server                  mesh 127.0.1.1:4443 ssl  verify none
```
  Test access to rmm-tactical.example.com and mesh-tactical.example.com

Full HAProxy config example available in HAProxy-Example.cfg
