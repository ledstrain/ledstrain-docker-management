FROM php:7.3.18-apache 

ENV APACHE_DOCUMENT_ROOT /var/www/html/public

RUN a2enmod rewrite


RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir /usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

RUN docker-php-ext-install mysqli pdo pdo_mysql

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd curl dom json mbstring openssl tokenizer zip 


ARG DEV_SITE

RUN echo "ServerName ${DEV_SITE}" >> /etc/apache2/apache2.conf

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

USER 1000
