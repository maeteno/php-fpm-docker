FROM ubuntu:16.04 as builder

LABEL maintainer="Alan <ssisoo@live.cn>"

ADD https://github.com/maeteno/php-software-package/raw/master/php-7.1.26.tar.gz /home/
ADD https://pecl.php.net/get/redis-4.2.0.tgz /home/
ADD https://pecl.php.net/get/mongodb-1.5.3.tgz /home/
ADD https://pecl.php.net/get/swoole-4.2.13.tgz /home/
ADD http://apache.01link.hk/zookeeper/zookeeper-3.4.13/zookeeper-3.4.13.tar.gz /home/
ADD https://pecl.php.net/get/zookeeper-0.6.3.tgz /home/

RUN apt-get update -y
RUN apt-get install -y apt-utils gcc g++ autoconf make 
RUN apt-get install -y libxml2-dev libssl-dev libbz2-dev libpng-dev libxslt1-dev libcurl4-openssl-dev 
RUN ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib

WORKDIR /home/

RUN cd /home/php-7.1.26/ &&\
    ./configure \
    --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --enable-zip \
    --enable-bcmath \
    --enable-exif \
    --enable-fpm \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-soap \
    --enable-sysvmsg \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-mysqlnd \
    --enable-sockets \
    --disable-cgi \
    --with-openssl \
    --with-zlib \
    --with-curl \
    --with-bz2 \
    --with-openssl \
    --with-gd \
    --with-mysqli \
    --with-xsl \
    --with-pdo-mysql \
    && make \
    && make install \
    && cp php.ini-production /usr/local/php/etc/php.ini 

ENV PATH=$PATH:/usr/local/php/bin

RUN cd /home/redis-4.2.0/ \
    && phpize && ./configure && make && make install \
    && echo "extension=redis.so" >> /usr/local/php/etc/php.ini

RUN cd /home/mongodb-1.5.3/ \
    && phpize && ./configure && make && make install \
    && echo "extension=mongodb.so" >> /usr/local/php/etc/php.ini

RUN cd /home/swoole-4.2.13/ \
    && phpize && ./configure --enable-sockets --enable-openssl --enable-mysqlnd \
    && make && make install \
    && echo "extension=swoole.so" >> /usr/local/php/etc/php.ini

RUN cd /home/zookeeper-3.4.13/src/c \
    && ./configure --prefix=/usr/local/zookeeper \
    && make && make install 

RUN cd /home/zookeeper-0.6.3/ \
    && phpize && ./configure --with-libzookeeper-dir=/usr/local/zookeeper \
    && make && make install \
    && echo "extension=zookeeper.so" >> /usr/local/php/etc/php.ini

# 运行阶段
FROM ubuntu:16.04

RUN apt-get update -y \
    && apt-get install -y libxml2-dev libssl-dev libbz2-dev libpng-dev libxslt1-dev libcurl4-openssl-dev \
    && ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib

# 从编译阶段的中拷贝编译结果到当前镜像中
COPY --from=builder /usr/local/php /usr/local/php 
COPY --from=builder /usr/local/zookeeper /usr/local/zookeeper 

ENV PATH=$PATH:/usr/local/php/bin 

CMD ["/usr/local/php/bin/php-fpm"]
