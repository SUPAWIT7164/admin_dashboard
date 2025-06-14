# ใช้ PHP FPM base image
FROM php:8.2-fpm

# ติดตั้ง PHP extensions และเครื่องมือที่จำเป็น
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    zip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    nodejs \
    npm \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ติดตั้ง Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ตั้ง Working Directory
WORKDIR /var/www

# คัดลอกไฟล์ composer.json และ composer.lock ก่อน
COPY composer.json composer.lock ./

# ติดตั้ง Composer dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts

# คัดลอกไฟล์ package.json และ package-lock.json
COPY package.json package-lock.json ./

# ติดตั้ง npm dependencies
RUN npm install

# คัดลอกโค้ดทั้งหมด
COPY . .

# สร้าง production assets
RUN npm run build \
    && composer dump-autoload --optimize \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# ตั้งค่าสิทธิ์
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# เปิด port 8080
EXPOSE 8080

# เริ่ม Laravel server
CMD php artisan serve --host=0.0.0.0 --port=8080 