# nginx-with-modsecurity
NGINX build with modsecurity incl OWASP rules and other nginx modules I use on Raspberry Pi 5

Versions:  
NGINX <!--NGINX_VERSION-->x.yy.z<!--NGINX_VERSION-->  
ModSecurity <!--MODSECURITY_VERSION-->vx.y.z<!--MODSECURITY_VERSION-->  
OWASP RuleSet: <!--OWASP_RULESET_VERSION-->vx.y.z<!--OWASP_RULESET_VERSION-->  

Includes the following modules:
GeoIP2
Subs filter
Headers more

Also changes the NGINX indentifiers which make it slightly harder to detect webserver type and version

Images are on [DockerHub](https://hub.docker.com/r/rweijnen/nginx-with-modsecurity)

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
