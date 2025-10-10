# nginx-with-modsecurity

[![Build and Push Docker Image](https://github.com/rweijnen/nginx-with-modsecurity-rpi/actions/workflows/docker-image.yml/badge.svg)](https://github.com/rweijnen/nginx-with-modsecurity-rpi/actions/workflows/docker-image.yml)

NGINX build with modsecurity incl OWASP rules and other nginx modules I use.
I originally made this for my Raspberry Pi 5 but I've added an AMD64 build on request.

The workflow runs every day and checks for new releases of NGINX, ModSecurity or the OWASP RuleSet and automatically builds a new image if a newer version is available.
Updated images are of course pushed to Docker Hub.

Contains:
- **[NGINX](http://nginx.org/)** (as reverse proxy)
- **[ModSecurity](https://github.com/SpiderLabs/ModSecurity)**:
  - A web application firewall (WAF) for real-time application monitoring, logging, and access control.
  - Includes the [OWASP ModSecurity Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset) for additional security rules.
- **[GeoIP2](https://github.com/leev/ngx_http_geoip2_module)**:
  - A module for NGINX that allows you to retrieve the geographical location of the client based on their IP address.
- **[Headers More](https://github.com/openresty/headers-more-nginx-module)**:
  - This module allows you to add, set, or clear any input or output headers for NGINX.
- **[Subs Filter Module](https://nginx.org/en/docs/http/ngx_http_sub_module.html)**:
  - A module that enables you to search and replace text in the response body before sending it to the client.

Versions:
Alpine <!--ALPINE_VERSION-->3.22.2<!--ALPINE_VERSION-->  
NGINX <!--NGINX_VERSION-->1.29.2<!--NGINX_VERSION-->  
ModSecurity <!--MODSECURITY_VERSION-->v3.0.14<!--MODSECURITY_VERSION-->  
OWASP RuleSet: <!--OWASP_RULESET_VERSION-->v4.19.0<!--OWASP_RULESET_VERSION-->  

**Latest Build Information:**  
Built: <!--BUILD_DATE-->2025-10-10 00:00 UTC<!--BUILD_DATE-->  
Reason: <!--BUILD_REASON-->Alpine Linux updated from 3.22.1 to 3.22.2<!--BUILD_REASON-->

**Latest Build Information:**  
Built: <!--BUILD_DATE-->2025-10-10 00:00 UTC<!--BUILD_DATE-->  
Reason: <!--BUILD_REASON-->Alpine Linux updated from 3.22.1 to 3.22.2<!--BUILD_REASON-->

Includes the following modules:
GeoIP2
Subs filter
Headers more

Also changes the NGINX indentifiers which make it slightly harder to detect webserver type and version

Images are on [DockerHub](https://hub.docker.com/r/rweijnen/nginx-with-modsecurity) and can be pulled with `docker pull rweijnen/nginx-with-modsecurity`.

Example docker-compose:
```version: '3.7'

services:
  nginx:
    image: rweijnen/nginx-with-modsecurity:latest
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    ports:
      - "443:443"
    volumes:
      - /srv/nginx/nginx.conf:/etc/nginx/nginx.conf
      - /etc/letsencrypt/:/etc/certs
      - /srv/nginx/html:/usr/share/nginx/html
      - /etc/GeoIP.conf:/etc/GeoIP.conf
      - /srv/nginx/GeoIP:/usr/share/GeoIP
    restart: unless-stopped
    networks:
      - vlan40net
      - internalnet

networks:
  vlan40net:
    external: true
  internalnet:
    external: true
```
