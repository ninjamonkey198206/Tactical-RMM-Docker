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
# Docker T-RMM Setup
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

##
###
# T-RMM HAProxy config, baremetal
###

**Requires HAProxy 2.4+**

## Ubuntu/Debian:

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

##
###
# T-RMM HAProxy config, PFSense
###

### Example for T-RMM, edit urls and ports to suit environment:

## [Install HAProxy-devel package](#install-haproxy-devel-package-1)

## [Firewall configuration](#firewall-configuration-1)

## [General HAProxy settings](#general-haproxy-settings-1)

## [Shared HTTP to HTTPS redirect frontend](#shared-http-to-https-redirect-frontend-1)

## [Mesh backend](#mesh-backend-1)

## [Mesh Websockets backend](#mesh-websockets-backend-1)

## [RMM backend](#rmm-backend-1)

###
## Install HAProxy-devel package
###
**Go to System > Package Manager**

![Screenshot 2022-04-24 092054](https://user-images.githubusercontent.com/24654529/164981179-a8516d84-4554-4007-837a-af70f2396390.png)
###

**Select Available Packages**

![Screenshot 2022-04-24 092520](https://user-images.githubusercontent.com/24654529/164981248-ce8549e8-5706-4145-a308-009238897d86.png)
###

**Find and install haproxy-devel**

![Screenshot 2022-04-24 092647](https://user-images.githubusercontent.com/24654529/164981427-fe2e47d4-7383-422e-9d19-bf2dbb2c2e50.png)
###

### 
## Firewall configuration
### 

**Go to Firewall > Rules**

![Screenshot 2022-04-24 093246](https://user-images.githubusercontent.com/24654529/164981702-69ec6cf0-65cb-44dc-9b98-4ca963d01fa7.png)
###

**Select the WAN tab**

![Screenshot 2022-03-31 135621](https://user-images.githubusercontent.com/24654529/161129178-55784d70-87d7-4d1d-b980-80c211b17bd0.png)
###

**Add the HAProxy_HTTP rule to the bottom of the list. Nothing else should have ports 80 or 443 in use.**

![Screenshot 2022-03-31 135726](https://user-images.githubusercontent.com/24654529/164981936-f61793b4-ce31-45fc-ae07-5026e6f8c04c.png)
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

![Screenshot 2022-04-24 094338](https://user-images.githubusercontent.com/24654529/164982082-77ec3c26-f6cb-4c70-9344-bab1e40d381e.png)
###

**Save the new rule and apply changes**

**Copy the HTTP rule, changing the To and From ports to HTTPS (443) and the description to HAProxy_HTTPS**

**Save the new rule and apply changes**
###

###
## General HAProxy settings
###

**Go to Services > HAProxy**

![Screenshot 2022-04-24 110804](https://user-images.githubusercontent.com/24654529/164985595-87a50a82-9edb-4906-bc9a-96dcf5c17e0e.png)
###

**Select the Settings tab**

**Fill in the entries as shown in the screen capture below, leaving the rest at defaults or tune them to your preference:**

Enable HAProxy = Checked

Reload behavior = Checked (closes existing connections to force reconnect to updated process after haproxy restart)

SSL/TLS Compatibility Mode = Intermediate (allows for maximum compatibility with all devices, select Modern at your own risk)

Max SSL Diffie-Hellman size = 2048 or 4096 (dealers choice)

![Screenshot 2022-04-24 101811](https://user-images.githubusercontent.com/24654529/164985436-3f83dc55-b6c3-4007-bd9b-6fded3f1e4e7.png)
###

**Save settings and apply changes**
###

###
## Shared HTTP to HTTPS redirect frontend 
###


**Go to the Frontend tab. Click the button to add a new frontend.**

**This shared http frontend will redirect all configured entries to their HTTPS equivalent and allow SSL offloading, as well as both internal and external access to the sites/services via URL.**

**Fill in the entries as shown in the screen captures below:**

Name = http_shared

Description = http_shared

Status = Active

External address = Listen address: any (IPv4), Port: 80

Type = http / https(offloading)

![Screenshot 2022-04-24 111255](https://user-images.githubusercontent.com/24654529/164986858-939ae79b-13d4-449a-8141-20c4ed209faa.png)
###

**Edit entries to suit your URLs**

**Access Control lists:**

First ACL = Name: rmm , Expression: Host matches , Value: rmm.example.com

Second ACL = Name: api , Expression: Host matches , Value: api.example.com

Third ACL = Name: mesh , Expression: Host matches , Value: mesh.example.com

**Actions:**

First action = Action: http-request redirect , Condition acl names: rmm , rule: scheme https

Second action = Action: http-request redirect , Condition acl names: api , rule: scheme https

Third action = Action: http-request redirect , Condition acl names: mesh , rule: scheme https

**Default Backend:** None

![Screenshot 2022-04-24 111257](https://user-images.githubusercontent.com/24654529/164986860-dd9dd3d0-445a-4657-be06-dbbc2e3d6422.png)
###

**Advanced Settings:**

Use "forwardfor" option = checked

Use "httpclose" option = http-server-close

Advanced pass thru =
```text
http-request add-header         X-Real-IP %[src]
```
![Screenshot 2022-04-24 112830](https://user-images.githubusercontent.com/24654529/164986864-d106d656-5c14-44bc-a64e-e6bf72126351.png)
###

Save and apply changes.

###
## Shared HTTPS frontend
###

**Fill in the entries as shown in the screen captures below:**

Name = https_shared

Description = https_shared

Status = Active

External address = Listen address: any (IPv4) , Port: 443 , SSL Offloading: checked

Type = http / https(offloading)

![Screenshot 2022-04-24 120859](https://user-images.githubusercontent.com/24654529/164988154-d12fb654-effe-410a-a309-b0d54bbe0bb8.png)
###

**Advanced Settings:**

Use "forwardfor" option = checked

Use "httpclose" option = http-server-close

Advanced pass thru =
```text
http-request add-header         X-Real-IP %[src]
```

![Screenshot 2022-04-24 112830](https://user-images.githubusercontent.com/24654529/164988116-735f9376-a5d5-4190-b563-22937f528324.png)
###

**SSL Offloading**

Certificate = configured LetsEncrypt Server cert , Add ACL for certificate Subject Alternative Names : checked

OCSP = checked

![Screenshot 2022-04-24 121022](https://user-images.githubusercontent.com/24654529/164988289-16546962-554d-4008-92fc-9bb0ed86f7bf.png)
###

Save and apply changes.

###
## Mesh backend
###

**Fill in the entries as shown in the screen captures below, changing entries to suit environment. Assumes port 4443 exposed on T-RMM proxy:**

Name = mesh.example.com

Server list = Mode: active , Name: mesh , Forwardto: Address+Port , Address: host server IP , Port: 4443 , Encrypt(SSL): yes/checked , SSL checks: no/unchecked

Connection timeout = 15000

Server timeout = 15000

Retries = 3

Health check method = none

![Screenshot 2022-04-24 124136](https://user-images.githubusercontent.com/24654529/164989354-4acd5e67-c76d-4259-85b8-94a980b8db7a.png)
###

**Advanced settings**

Backend pass thru =
```text
timeout tunnel      15000
http-request add-header X-Forwarded-Host %[req.hdr(Host)]
http-request add-header X-Forwarded-Proto https
```

![Screenshot 2022-04-24 124205](https://user-images.githubusercontent.com/24654529/164989357-d88d3090-24e1-4449-8da2-6885616388ba.png)
###

Save and apply changes.

###
## Mesh Websockets backend
###

**Fill in the entries as shown in the screen captures below, changing entries to suit environment:**

Name = mesh.example.com-websocket

Server list = Mode: active , Name: mesh-websocket , Forwardto: Address+Port , Address: host server IP , Port: 4443 , Encrypt(SSL): yes/checked , SSL checks: no/unchecked

Connection timeout = 3000

Server timeout = 3000

Retries = 3

Health check method = none

![Screenshot 2022-04-24 125249](https://user-images.githubusercontent.com/24654529/164989799-5a5ad85d-0180-4597-910d-96809037c35f.png)
###

**Advanced settings**

Backend pass thru =
```text
timeout tunnel      3600000
http-request add-header X-Forwarded-Host %[req.hdr(Host)]
http-request add-header X-Forwarded-Proto https
```

![Screenshot 2022-04-24 125312](https://user-images.githubusercontent.com/24654529/164989801-ee2e11d1-b643-4400-be35-3576e59884d4.png)
###

Save and apply changes.

###
## RMM backend
###
