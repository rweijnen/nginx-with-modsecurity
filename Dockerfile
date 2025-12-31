# Define the NGINX version to use for consistency in both stages
ARG NGINX_VERSION=1.21.6

# First stage: Build the ngx_http_subs_filter_module, ngx_http_geoip2_module, and ModSecurity
#FROM --platform=linux/arm64/v8 alpine:latest AS builder
FROM alpine:latest AS builder

# Install build dependencies required for building NGINX and the modules, including ModSecurity dependencies
RUN apk add --update --no-cache \
    build-base \
    pcre2 pcre2-dev \
    zlib zlib-dev \
    openssl openssl-dev \
    wget \
    git \
    libmaxminddb-dev \
    libmaxminddb \
    linux-headers \
    libxml2-dev \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    automake \
    autoconf \
    libtool \
    pkgconfig \
    bash

# Download NGINX source code
ARG NGINX_VERSION
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxvf nginx-${NGINX_VERSION}.tar.gz

# Perform search and replace in ngx_http_special_response.c
RUN sed -i 's|<hr><center>nginx</center>|<hr><center>Reynholm Industries</center>|g' nginx-${NGINX_VERSION}/src/http/ngx_http_special_response.c && \
	sed -i 's|Server: nginx|Server: Reynholm Industries|g' nginx-${NGINX_VERSION}/src/http/ngx_http_header_filter_module.c && \
    sed -i 's|nginx/|Reynholm Industries/|g' nginx-${NGINX_VERSION}/src/core/nginx.h

# Clone the required modules
RUN git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module && \
    git clone https://github.com/leev/ngx_http_geoip2_module.git && \
    git clone https://github.com/openresty/headers-more-nginx-module && \
    git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

# Build ModSecurity
RUN cd ModSecurity && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && \
    make && \
    make install

# Prepare ModSecurity configuration
RUN cp /ModSecurity/modsecurity.conf-recommended /ModSecurity/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /ModSecurity/modsecurity.conf

# Compile NGINX with additional modules
RUN cd nginx-${NGINX_VERSION} && \
    ./configure --with-compat \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/run/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --modules-path=/usr/lib/nginx/modules \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-http_ssl_module \
	--with-http_v2_module \
    --with-http_sub_module \
    --add-dynamic-module=../ngx_http_substitutions_filter_module \
    --add-dynamic-module=../ngx_http_geoip2_module \
    --add-dynamic-module=../headers-more-nginx-module \
    --add-dynamic-module=../ModSecurity-nginx && \
    make && make install

# Setup OWASP ModSecurity Core Rule Set
#RUN wget https://github.com/coreruleset/coreruleset/archive/v3.3.0.tar.gz && \
#    tar -xzf v3.3.0.tar.gz && \
#    mv coreruleset-3.3.0 /usr/local/coreruleset && \
#    cp /usr/local/coreruleset/crs-setup.conf.example /usr/local/coreruleset/crs-setup.conf
# Setup OWASP ModSecurity Core Rule Set
RUN for i in 1 2 3; do \
        echo "Attempt $i: Fetching OWASP CRS release info..." && \
        TARBALL_URL=$(wget --timeout=30 --tries=3 -qO- "https://api.github.com/repos/coreruleset/coreruleset/releases/latest" | \
            grep "tarball_url" | \
            cut -d '"' -f 4) && \
        if [ -n "$TARBALL_URL" ]; then \
            echo "Successfully got tarball URL: $TARBALL_URL" && \
            break; \
        else \
            echo "Attempt $i failed, retrying in 5 seconds..." && \
            sleep 5; \
        fi; \
    done && \
    if [ -z "$TARBALL_URL" ]; then \
        echo "ERROR: All attempts to fetch tarball URL failed" && \
        exit 1; \
    fi && \
    wget -O coreruleset.tar.gz "$TARBALL_URL" && \
    mkdir coreruleset && \
    tar -xzf coreruleset.tar.gz --strip-components=1 -C coreruleset && \
    mv coreruleset /usr/local/coreruleset && \
    cp /usr/local/coreruleset/crs-setup.conf.example /usr/local/coreruleset/crs-setup.conf


# Second stage: Set up the environment for our custom-compiled NGINX
#FROM --platform=linux/arm64/v8 alpine:latest
FROM alpine:latest

# Install runtime dependencies
RUN apk add --update --no-cache \
    libstdc++ \
    pcre \
    pcre2 \ 
    libmaxminddb \
    openssl \
    libxml2 \
    libxslt \
    gd \
    geoip 

# Create 'nginx' user and group
RUN addgroup -S nginx && adduser -S -G nginx nginx

# Copy the compiled NGINX binary and modules from the builder stage
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/lib/nginx/modules /usr/lib/nginx/modules

# Copy ModSecurity library files from the builder stage
COPY --from=builder /usr/local/modsecurity /usr/local/modsecurity
COPY --from=builder /usr/local/coreruleset /etc/nginx/modsecurity/coreruleset

# copy unicode.mapping
COPY --from=builder /ModSecurity/unicode.mapping /etc/nginx/modsecurity/unicode.mapping

# Make sure directories exist (create them if they don't) and set proper permissions
RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /etc/nginx /usr/lib/nginx/modules /var/run/nginx && \
    chmod -R 755 /var/log/nginx /var/cache/nginx /usr/lib/nginx/modules

# Forward request and error logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Configure ModSecurity and CRS
# Copy ModSecurity configuration files from the builder stage
COPY --from=builder /ModSecurity/modsecurity.conf /etc/nginx/modsecurity/modsecurity.conf
RUN sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/nginx/modsecurity/modsecurity.conf && \
    echo "" >> /etc/nginx/modsecurity/modsecurity.conf && \
    echo "# PCRE limits - increased from default 1500 to avoid MSC_PCRE_LIMITS_EXCEEDED errors" >> /etc/nginx/modsecurity/modsecurity.conf && \
    echo "SecPcreMatchLimit 50000" >> /etc/nginx/modsecurity/modsecurity.conf && \
    echo "SecPcreMatchLimitRecursion 50000" >> /etc/nginx/modsecurity/modsecurity.conf

# Create conf.d directory for user overrides with empty placeholder
# (ModSecurity doesn't support IncludeOptional, so we need a file to exist)
RUN mkdir -p /etc/nginx/modsecurity/conf.d && \
    echo "# Place custom ModSecurity overrides here" > /etc/nginx/modsecurity/conf.d/00-placeholder.conf

RUN	touch /etc/nginx/modsecurity/main.conf && \
    echo "Include /etc/nginx/modsecurity/modsecurity.conf" > /etc/nginx/modsecurity/main.conf && \
    echo "Include /etc/nginx/modsecurity/coreruleset/crs-setup.conf" >> /etc/nginx/modsecurity/main.conf && \
    echo "Include /etc/nginx/modsecurity/coreruleset/rules/*.conf" >> /etc/nginx/modsecurity/main.conf && \
    echo "# Include custom overrides (mount your .conf files to /etc/nginx/modsecurity/conf.d/)" >> /etc/nginx/modsecurity/main.conf && \
    echo "Include /etc/nginx/modsecurity/conf.d/*.conf" >> /etc/nginx/modsecurity/main.conf

# Create necessary directories
RUN mkdir -p /etc/nginx/conf.d /var/log/nginx /var/cache/nginx /var/run/nginx /usr/lib/nginx/modules

# Now, safely create load_module.conf with required module load instructions
RUN echo 'load_module "/usr/lib/nginx/modules/ngx_http_subs_filter_module.so";' > /etc/nginx/conf.d/load_module.conf && \
    echo 'load_module "/usr/lib/nginx/modules/ngx_http_geoip2_module.so";' >> /etc/nginx/conf.d/load_module.conf && \
    echo 'load_module "/usr/lib/nginx/modules/ngx_http_modsecurity_module.so";' >> /etc/nginx/conf.d/load_module.conf && \
    echo 'load_module "/usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so";' >> /etc/nginx/conf.d/load_module.conf

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
