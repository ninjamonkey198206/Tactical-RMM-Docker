# Tactical-RMM-Docker

###
## [Docker T-RMM Setup](#docker-t-rmm-setup-1)
###

###
## [T-RMM HAProxy config, baremetal](#t-rmm-haproxy-config-baremetal-1)
###

###
## [T-RMM HAProxy config, PFSense](#t-rmm-haproxy-config-pfsense-1)
###


###
## Docker T-RMM Setup
###

1) In env file change GATEWAY, SUBNET, and IP variables for the various networks and containers, API, APP, and MESH URL variables to suit environment. Edit remaining env to suit your config.
###

  **If running HAProxy on same system as docker containers, set http and https exp port variables to 127.0.1.1:port**
###

  **Keep NATS exp port variable as 4222 and ensure firewall access. This requires a TCP only reverse proxy, and is not http traffic, so it cannot be routed through a proxy on port 443 along with the rest.**
###

  **If running IPTables firewall in Drop All by default with HAProxy on the same system, make sure to add the following:**
```text
# This ensures communication because HAProxy and Docker don't play nice with Drop all by default
-A INPUT -i trmmproxy -p tcp -m multiport --sports 4443,8080 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
-A INPUT -i trmmproxy -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A OUTPUT -o trmmproxy -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -o trmmnats -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
```
###
2) Add RMM, API, and Mesh sites to /etc/hosts
```text
127.0.1.1 api-tactical.example.com api-tactical
127.0.1.1 rmm-tactical.example.com rmm-tactical
127.0.1.1 mesh-tactical.example.com mesh-tactical
```
###
### First Run:

1) Bring up stack once, then immediately stop the stack.

2) Copy valid fullchain cert and private key to "/path/to/docker/volumes/name_of_stack_data/_data/certs/" as fullchain.pem and privkey.pem respectively.

3) Start stack, verify access after init complete.

4) Log into mesh.example.com and configure 2fa, as well as client remote access settings for notification, permission, etc.

###
## T-RMM HAProxy config, baremetal
###

**Requires HAProxy 2.4+**

### Ubuntu/Debian:

Make sure firewall rules are in place, then edit HAProxy config.

**Assumes existing shared http to https redirect and https frontends. See full HAProxy config example in [HAProxy-Example.cfg](https://github.com/ninjamonkey198206/Tactical-RMM-Docker/blob/main/HAProxy-Example.cfg) if starting from scratch for reference to configure global, default, and shared http redirect and https front ends before continuing.**

**Example for T-RMM, edit urls and ports to suit environment:**
  
  If not already present, add to both http and https shared frontends
```text
option                          forwardfor
http-request add-header         X-Real-IP %[src]
```
###
  Add http to https redirects for Mesh, RMM, and API in shared http frontend
```text
acl                     rmm     var(txn.txnhost) -m str -i rmm-tactical.example.com
acl                     api     var(txn.txnhost) -m str -i api-tactical.example.com
acl                     mesh    var(txn.txnhost) -m str -i mesh-tactical.example.com
http-request redirect scheme https  if  rmm
http-request redirect scheme https  if  api
http-request redirect scheme https  if  mesh
```
###
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
###
  Add backends
```text
backend rmm-tactical.example.com_ipvANY
        mode                    http
        log                     global
        timeout connect         30000
        timeout server          30000
        retries                 3
        http-request add-header X-Forwarded-Host %[req.hdr(Host)]
        http-request add-header X-Forwarded-Proto https
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
###
  Restart HAProxy service.
  
  Test access to rmm-tactical.example.com and mesh-tactical.example.com

###
## T-RMM HAProxy config, PFSense
###

### Example for T-RMM, edit urls and ports to suit environment:

### Install HAProxy-devel package
**Go to System > Package Manager**

![Screenshot 2022-03-31 125739](https://user-images.githubusercontent.com/24654529/161121728-ae0c7023-9896-4ec4-bb44-03db3760cdb7.png)
###

**Select Available Packages**

![Screenshot 2022-03-31 130058](https://user-images.githubusercontent.com/24654529/161121800-e5babfd9-29ed-433a-b0c7-850a5aa5b017.png)
###

**Find and install haproxy-devel**

![Screenshot 2022-03-31 130322](https://user-images.githubusercontent.com/24654529/161121985-953e24a6-bcaa-418d-a1e4-1ef62a193623.png)
###
###

### Firewall configuration
###

**Go to Firewall > Rules**

![Screenshot 2022-03-31 135327](https://user-images.githubusercontent.com/24654529/161128877-85aec1f2-c829-4700-81ca-7e78a112d891.png)
###

**Select the WAN tab**

![Screenshot 2022-03-31 135621](https://user-images.githubusercontent.com/24654529/161129178-55784d70-87d7-4d1d-b980-80c211b17bd0.png)
###

**Add the following two rules to the bottom of the list, nothing else should be using ports 80 and 443:**

![Screenshot 2022-03-31 135726](https://user-images.githubusercontent.com/24654529/161129621-9809859c-f50f-45f9-bef8-635036189fef.png)
###

**HTTP rule:**

Action = Pass

Interface = WAN

Address Family = IPv4

Source = any

Destination = This firewall (self)

Destination Port Range = From: HTTP (80), To: HTTP (80)

Log = Log packets ***optional***

Description = HAProxy_HTTP

![Screenshot 2022-03-31 140214](https://user-images.githubusercontent.com/24654529/161130992-8d2af2d4-a448-4b2a-a2dc-f9e01174b85a.png)
###

**Save the new rule and apply changes**
###

**Create a duplicate rule, changing the port to 443 and the description for HTTPS**

**Enable the new rules.**
