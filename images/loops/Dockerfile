# syntax=docker/dockerfile:1

ARG IMAGE_VERSION="v1.0.0-beta.1"

FROM php:8.4-fpm AS builder

ARG IMAGE_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    git \
    libpq-dev \
    libonig-dev \
    libssl-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libzip-dev \
    && docker-php-ext-configure pcntl --enable-pcntl \
    && docker-php-ext-install -j"$(nproc)" \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    opcache \
    intl \
    zip \
    bcmath \
    soap \
    pcntl \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www

RUN curl -sSL https://github.com/joinloops/loops-server/archive/refs/tags/${IMAGE_VERSION}.tar.gz \
    | tar -xz --strip-components=1

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress --prefer-dist

FROM php:8.4-fpm

COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/bin/docker-php-ext-* /usr/local/bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    libfcgi-bin \
    procps \
    ffmpeg \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -o /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

WORKDIR /var/www

COPY --from=builder /var/www /var/www

COPY docker/php-fpm/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN sed -i '/\[www\]/a pm.status_path = /status' /usr/local/etc/php-fpm.d/zz-docker.conf

RUN chown -R www-data:www-data /var/www

USER www-data

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EXPOSE 8080
CMD ["php-fpm"]
