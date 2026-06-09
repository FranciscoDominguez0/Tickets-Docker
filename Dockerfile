FROM php:8.2-apache

# =========================
# 🔧 INSTALAR DEPENDENCIAS
# =========================
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libzip-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# =========================
# 📦 COMPOSER
# =========================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# =========================
# 🔥 EXTENSIONES PHP
# =========================
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    gd \
    exif \
    zip

# =========================
# ⚡ OPCACHE
# =========================
RUN echo "opcache.enable=1" > /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.validate_timestamps=1" >> /usr/local/etc/php/conf.d/opcache.ini

# =========================
# 🔒 SEGURIDAD PHP
# =========================
RUN echo "expose_php=Off" > /usr/local/etc/php/conf.d/security.ini && \
    echo "display_errors=Off" >> /usr/local/etc/php/conf.d/security.ini && \
    echo "log_errors=On" >> /usr/local/etc/php/conf.d/security.ini && \
    echo "session.cookie_httponly=1" >> /usr/local/etc/php/conf.d/security.ini && \
    echo "session.use_strict_mode=1" >> /usr/local/etc/php/conf.d/security.ini

# =========================
# ⚙️ CONFIG PHP
# =========================
RUN echo "upload_max_filesize=32M" > /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size=32M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit=256M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time=60" >> /usr/local/etc/php/conf.d/uploads.ini

# =========================
# 🌐 APACHE
# =========================
RUN a2enmod rewrite deflate headers

RUN echo "ServerTokens Prod" >> /etc/apache2/apache2.conf && \
    echo "ServerSignature Off" >> /etc/apache2/apache2.conf

RUN echo "<Directory /var/www/html>" >> /etc/apache2/apache2.conf && \
    echo "    Options -Indexes" >> /etc/apache2/apache2.conf && \
    echo "    AllowOverride All" >> /etc/apache2/apache2.conf && \
    echo "    Require all granted" >> /etc/apache2/apache2.conf && \
    echo "</Directory>" >> /etc/apache2/apache2.conf

# =========================
# 📁 COPIAR PROYECTO
# =========================
COPY app/sistema-tickets /var/www/html/sistema-tickets

WORKDIR /var/www/html/sistema-tickets

# =========================
# 📦 INSTALAR LIBRERÍAS COMPOSER
# =========================
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader; \
    fi

# =========================
# 🌐 DOCUMENT ROOT
# =========================
RUN sed -i 's#/var/www/html#/var/www/html/sistema-tickets#g' \
    /etc/apache2/sites-available/000-default.conf

# =========================
# 🔐 PERMISOS
# =========================
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# =========================
# 🚪 PUERTO
# =========================
EXPOSE 80