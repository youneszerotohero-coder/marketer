FROM php:8.3-cli-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    bash \
    curl \
    git \
    libaio1 \
    libicu-dev \
    libpq-dev \
    libzip-dev \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/oracle \
    && curl -fsSL -o /tmp/instantclient-basiclite.zip https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-basiclite-linux.x64-23.7.0.25.01.zip \
    && curl -fsSL -o /tmp/instantclient-sdk.zip https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-sdk-linux.x64-23.7.0.25.01.zip \
    && unzip -o -q /tmp/instantclient-basiclite.zip -d /opt/oracle \
    && unzip -o -q /tmp/instantclient-sdk.zip -d /opt/oracle \
    && rm /tmp/instantclient-basiclite.zip /tmp/instantclient-sdk.zip \
    && ln -s /opt/oracle/instantclient_* /opt/oracle/instantclient \
    && echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig \
    && docker-php-ext-install intl pdo_pgsql zip \
    && echo 'instantclient,/opt/oracle/instantclient' | pecl install oci8 \
    && docker-php-ext-enable oci8

ENV LD_LIBRARY_PATH=/opt/oracle/instantclient

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
