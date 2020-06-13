FROM nginx:1.18
ENV NCHAN_VERSION 1.2.7

RUN echo "deb-src https://nginx.org/packages/debian/ buster nginx" >> /etc/apt/sources.list.d/nginx.list \
&& apt-get update \
&& apt-get install -y dpkg-dev \
&& apt-get build-dep -y nginx \
&& tempDir=/root \
&& cd "$tempDir" \
# Intall nginx source package
&& apt-get source nginx \
&& cd "$tempDir/nginx-1.18.0/" \
# Download nchan source
&& curl -fSL https://github.com/slact/nchan/archive/v$NCHAN_VERSION.tar.gz -o nchan.tar.gz \
&& tar -xzf nchan.tar.gz \
# Configure, build and copy nchan module
&& ./configure --with-compat --add-dynamic-module=nchan-$NCHAN_VERSION \
&& make modules \
&& cp objs/ngx_nchan_module.so /etc/nginx/modules/

# Install nginx confgiuration with predefined nchan locations
COPY nginx.conf /etc/nginx/nginx.conf
# Install req.conf to generate self signed certificate
COPY openssl-req.conf /root/

# Create ssl certificate and key
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/localhost-selfsigned.key -out /etc/ssl/certs/localhost-selfsigned.crt -config /root/openssl-req.conf
