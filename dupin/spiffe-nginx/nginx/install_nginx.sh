#!/bin/bash

# declare -r NGINX_VERSION="nginx-1.13.9spiffe2"
declare -r NGINX_VERSION="nginx-ryan-spiffe"
# declare -r NGINX_URL="https://s3.us-east-2.amazonaws.com/scytale-artifacts/nginx/${NGINX_VERSION}.tgz"
declare -r NGINX_URL="https://ryan.net/misc/nginx-ryan-spiffe.tgz"
declare -r NGINX_DIR="/usr/local/nginx"
declare -r NGINX_LOGS_DIR="${NGINX_DIR}/logs"

# Uncompress and move nginx
mkdir /opt/spiffe-nginx
curl --progress-bar --location ${NGINX_URL} | tar xzf -
mv -v ${NGINX_VERSION}/nginx /opt/spiffe-nginx
rm -R ${NGINX_VERSION}

# Create log folder 
mkdir -p ${NGINX_LOGS_DIR}
touch ${NGINX_LOGS_DIR}/access.log  ${NGINX_LOGS_DIR}/error.log
chmod 777 -R ${NGINX_LOGS_DIR}
chmod 777 ${NGINX_DIR}

# Create certs forlder
mkdir /certs
chmod 777 /certs

# Create blog user
useradd -m nginx-blog

# There is a bug in docker where /dev/stdout return permission error
echo 'chmod 777 /dev/stdout' >> ~/.bashrc

#---- replace nginx conf file with new syntax.  Doing this here, as a hack, because I don't own the base docker image,
#---- which is where the files currently come from in this repo.

cat << EOF > /usr/local/nginx/nginx_blog.conf
daemon off;
## pid /certs/nginx.pid;
user nginx-blog;
pid /home/nginx-blog/nginx.pid;
worker_processes 1;
error_log /dev/stdout debug;
events {
  worker_connections 1024;
}

http {
  server {
    listen       8443 ssl;
    server_name  localhost;

    # Fetch SVIDs
    ssl_spiffe_sock       /tmp/agent.sock;
    ## svid_file_path        /certs/blog_svid.pem;
    ## svid_key_file_path    /certs/blog_svid_key.pem;
    ## svid_bundle_file_path /certs/blog_svid_bundle.pem;
    ssl on;

    ssl_verify_client on;
    ## ssl_certificate         /certs/blog_svid.pem;
    ## ssl_certificate_key     /certs/blog_svid_key.pem;
    ## ssl_client_certificate  /certs/blog_svid_bundle.pem;

    ssl_spiffe on;
    ssl_spiffe_accept spiffe://example.org/host/front-end;

    location / {
      root   html;
      index  index.html index.htm;
    }
  }
}
EOF


#----- likewise, replace the nginx fe conf file:
cat << EOF > /usr/local/nginx/nginx_fe.conf
daemon off;
user root;
pid /root/nginx.pid;
worker_processes 1;
error_log /dev/stdout debug;
events {
  worker_connections 1024;
}

http {
  server {
    listen      80;
    server_name localhost;

    # Fetch SVIDs
    ssl_spiffe_sock       /tmp/agent.sock;
##    svid_file_path        /certs/front_end_svid.pem;
##    svid_key_file_path    /certs/front_end_svid_key.pem;
##    svid_bundle_file_path /certs/front_end_svid_bundle.pem;

    proxy_ssl_verify              on;
##    proxy_ssl_certificate         /certs/front_end_svid.pem;
##    proxy_ssl_certificate_key     /certs/front_end_svid_key.pem;
##    proxy_ssl_trusted_certificate /certs/front_end_svid_bundle.pem;

    proxy_ssl_spiffe on;
    proxy_ssl_spiffe_accept spiffe://example.org/host/blog;

    location / {
      root   html;
      index  index.html index.htm;
      proxy_pass https://127.0.0.1:8443$request_uri;
    }
  }
}
EOF


# Clean installation files
rm install_nginx.sh
