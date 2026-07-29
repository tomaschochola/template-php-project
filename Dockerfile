# syntax=docker/dockerfile:1

FROM docker.io/library/composer:2 AS versionedcomposer
FROM docker.io/library/php:8.5-fpm-trixie AS versionedphp
FROM docker.io/nginxinc/nginx-unprivileged:1-trixie AS versionednginx
FROM container-registry.oracle.com/mysql/community-server:9.6 AS versionedmysql
FROM docker.io/valkey/valkey:9-trixie AS versionedvalkey

FROM versionedphp AS base
WORKDIR /var/www/html
ENV APP_ENV=production
ENV NODE_ENV=production
RUN <<EOF
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get upgrade -y --no-install-recommends
  apt-get install -y --no-install-recommends libfcgi-bin
  pecl channel-update pecl.php.net
  pecl install apcu redis
  docker-php-ext-enable apcu redis
  apt-get autoremove -y
  apt-get autoclean -y
  apt-get clean -y
  rm -rf /var/lib/apt/lists/*
EOF
COPY ./ops/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY --from=versionedcomposer /usr/bin/composer /usr/bin/composer

FROM base AS devcontainer
ENV APP_ENV=local
ENV NODE_ENV=development
RUN <<EOF
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get upgrade -y --no-install-recommends
  apt-get install -y --no-install-recommends ca-certificates curl wget build-essential git zip unzip
  docker-php-ext-install pcntl
  pecl install xdebug
  docker-php-ext-enable xdebug
  apt-get install -y --no-install-recommends libzip-dev
  docker-php-ext-install zip
  apt-get install -y --no-install-recommends libicu-dev
  docker-php-ext-install intl
  mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
  groupadd devcontainer
  useradd -s /bin/bash --gid devcontainer -m devcontainer
  install -d -o devcontainer -g devcontainer /home/devcontainer/.composer/cache /home/devcontainer/.npm
  wget https://nodejs.org/dist/v24.18.0/node-v24.18.0-linux-x64.tar.xz -O node.tar.xz
  tar -xf node.tar.xz -C /usr/local --strip-components=1
  rm node.tar.xz
  apt-get autoremove -y
  apt-get autoclean -y
  apt-get clean -y
  rm -rf /var/lib/apt/lists/*
EOF
COPY ./ops/php/z.ini /usr/local/etc/php/conf.d/z.ini
COPY ./ops/php/zz.ini /usr/local/etc/php/conf.d/zz.ini
COPY ./ops/php/zzz.ini /usr/local/etc/php/conf.d/zzz.ini
USER devcontainer

FROM versionedcomposer AS vendor
WORKDIR /app
COPY ./composer* ./
RUN <<EOF
  set -euo pipefail
  composer install --no-plugins --no-scripts --no-dev --no-autoloader --ignore-platform-reqs
EOF

FROM base AS php
COPY --chown=www-data:www-data --from=vendor /app/composer* ./
COPY --chown=www-data:www-data --from=vendor /app/vendor ./vendor
COPY --chown=www-data:www-data ./index.php ./index.php
COPY --chown=www-data:www-data ./src ./src
USER www-data
RUN <<EOF
  set -euo pipefail
  composer dump-autoload --no-plugins --no-scripts --no-dev --classmap-authoritative --strict-psr --strict-ambiguous
  composer audit --no-plugins --no-scripts --no-dev
  composer check-platform-reqs --no-plugins --no-scripts --no-dev
  composer validate --no-plugins --no-scripts --strict --with-dependencies --check-lock
  mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
EOF
COPY ./ops/php/z.ini /usr/local/etc/php/conf.d/z.ini
COPY ./ops/php/zz.ini /usr/local/etc/php/conf.d/zz.ini
COPY --chmod=755 ./ops/php/entrypoint.sh /usr/local/bin/docker-php-entrypoint

FROM versionednginx AS nginx
USER root
WORKDIR /var/www/html
COPY ./ops/nginx /etc/nginx
COPY --chown=nginx:nginx ./public ./
RUN <<EOF
	set -euo pipefail
	apt-get update -y
	apt-get upgrade -y --no-install-recommends
	openssl req -x509 -newkey rsa:4096 -nodes -sha256 -keyout /etc/nginx/snakeoil.key -out /etc/nginx/snakeoil.pem -days 3650 -subj "/CN=localhost" -addext "subjectAltName=DNS:*.localhost,DNS:localhost"
	apt-get autoremove -y
	apt-get autoclean -y
	apt-get clean -y
	rm -rf /var/lib/apt/lists/*
EOF
USER nginx

FROM versionedmysql AS mysql
RUN <<EOF
  set -euo pipefail
  mkdir -p /etc/dnf/vars
  : > /etc/dnf/vars/ociregion
  microdnf upgrade -y
  microdnf clean all
  rm -rf /var/cache/dnf /var/cache/yum
EOF
COPY ./ops/mysql /docker-entrypoint-initdb.d

FROM versionedvalkey AS valkey
RUN <<EOF
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get upgrade -y --no-install-recommends
  apt-get autoremove -y
  apt-get autoclean -y
  apt-get clean -y
  rm -rf /var/lib/apt/lists/*
EOF
