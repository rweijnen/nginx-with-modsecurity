# NGINX with ModSecurity (for RPi(5) and AMD64)

This Docker image contains a custom-built version of NGINX. 

The build uses the latest available mainline version of NGINX and includes the following modules, along with their dependencies:

## Components

- **[NGINX](http://nginx.org/)** (as reverse proxy) - Version: <!--NGINX_VERSION-->placeholder<!--NGINX_VERSION-->
- **[ModSecurity](https://github.com/SpiderLabs/ModSecurity)** - Version: <!--MODSECURITY_VERSION-->placeholder<!--MODSECURITY_VERSION-->
  - A web application firewall (WAF) for real-time application monitoring, logging, and access control.
  - Includes the [OWASP ModSecurity Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset) - Version: <!--OWASP_RULESET_VERSION-->placeholder<!--OWASP_RULESET_VERSION--> for additional security rules.
- **[GeoIP2](https://github.com/leev/ngx_http_geoip2_module)**:
  - A module for NGINX that allows you to retrieve the geographical location of the client based on their IP address.
- **[Headers More](https://github.com/openresty/headers-more-nginx-module)**:
  - This module allows you to add, set, or clear any input or output headers for NGINX.
- **[Subs Filter Module](https://nginx.org/en/docs/http/ngx_http_sub_module.html)**:
  - A module that enables you to search and replace text in the response body before sending it to the client.

## Build Information
- **Build Date:** <!--BUILD_DATE-->placeholder<!--BUILD_DATE-->
- **Alpine Linux Version:** <!--ALPINE_VERSION-->placeholder<!--ALPINE_VERSION-->

## Repository and Contributions

- The source code and Dockerfile for this image are hosted on GitHub: [NGINX with ModSecurity](https://github.com/rweijnen/nginx-with-modsecurity).
- Feel free to contribute by submitting issues or pull requests.
