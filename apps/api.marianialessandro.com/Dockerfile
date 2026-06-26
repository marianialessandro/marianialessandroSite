FROM php:8.4-cli-alpine

WORKDIR /var/www/html

RUN apk add --no-cache \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    $PHPIZE_DEPS \
  && docker-php-ext-install \
    intl \
    mbstring \
    opcache \
    pdo_mysql \
    zip \
  && apk del $PHPIZE_DEPS

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
