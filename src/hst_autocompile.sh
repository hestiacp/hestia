# Autocompile Script for HestiaCP deb Files.

# Set compilation directory
BUILD_DIR='/root'
INSTALL_DIR='/usr/local/hestia'

# Set git repository raw path
GIT_REP='https://raw.githubusercontent.com/hestiacp/hestiacp/master/src/deb'

# Set Version for compiling
HESTIA_V='0.9.8-24_amd64'
NGINX_V='1.15.6'
OPENSSL_V='1.1.1'
PCRE_V='8.42'
ZLIB_V='1.2.11'
PHP_V='7.2.11'

# Generate links for source code
HESTIA='https://github.com/hestiacp/hestiacp/archive/master.zip'
NGINX='https://nginx.org/download/nginx-'$NGINX_V'.tar.gz'
OPENSSL='https://www.openssl.org/source/openssl-'$OPENSSL_V'.tar.gz'
PCRE='https://ftp.pcre.org/pub/pcre/pcre-'$PCRE_V'.tar.gz'
ZLIB='https://www.zlib.net/zlib-'$ZLIB_V'.tar.gz'
PHP='http://de2.php.net/distributions/php-'$PHP_V'.tar.gz'

# Set package dependencies for compiling
SOFTWARE='build-essential libxml2-dev libz-dev libcurl4-gnutls-dev unzip'

# Define a timestamp function
timestamp() {
    date +%s
}

# Install required software
echo "Update system repository..."
apt-get -qq update
echo "Installing dependencies for compilation..."
apt-get -qq install -y $SOFTWARE

# Fix for Debian PHP Environment
if [ ! -e /usr/local/include/curl ]; then
    ln -s /usr/include/x86_64-linux-gnu/curl /usr/local/include/curl
fi

# Set packages to be compiled
for arg; do
  case "$1" in
    --all)
      NGINX_B='true'
      PHP_B='true'
      HESTIA_B='true'
      ;;
    --nginx)
      NGINX_B='true'
      ;;
    --php)
      PHP_B='true'
      ;;
    --hestia)
      HESTIA_B='true'
      ;;
    *)
      NOARGUMENT='true'
      ;;
  esac
done

if [[ $# -eq 0 ]] ; then
  echo "!!! Please run with argument --all, --hestia, --nginx or --php !!!"
  exit 1
fi


#################################################################################
#
# Building hestia-nginx
#
#################################################################################

if [ "$NGINX_B" = true ] ; then
  # Change to build directory
  cd $BUILD_DIR
  
  # Check if target directory exists
  if [ -d $BUILD_DIR/hestia-nginx_$HESTIA_V ]; then
  	#mv $BUILD_DIR/hestia-nginx_$HESTIA_V $BUILD_DIR/hestia-nginx_$HESTIA_V-$(timestamp)
  	rm -r $BUILD_DIR/hestia-nginx_$HESTIA_V
  fi
  
  # Create directory
  mkdir $BUILD_DIR/hestia-nginx_$HESTIA_V
  
  # Download and unpack source files
  wget -qO- $NGINX | tar xz
  wget -qO- $OPENSSL | tar xz
  wget -qO- $PCRE | tar xz
  wget -qO- $ZLIB | tar xz
  
  # Change to nginx directory
  cd nginx-$NGINX_V
  
  # Configure nginx
  ./configure 	--prefix=/usr/local/hestia/nginx \
  		--with-http_ssl_module \
  		--with-openssl=../openssl-$OPENSSL_V \
  		--with-openssl-opt=enable-ec_nistp_64_gcc_128 \
  		--with-openssl-opt=no-nextprotoneg \
  		--with-openssl-opt=no-weak-ssl-ciphers \
  		--with-openssl-opt=no-ssl3 \
  		--with-pcre=../pcre-$PCRE_V \
  	        --with-pcre-jit \
  		--with-zlib=../zlib-$ZLIB_V
  
  # Check installation directory and move it if it exists
  if [ -d $INSTALL_DIR ]; then
  	#mv $INSTALL_DIR $INSTALL_DIR$(timestamp)
  	rm -r $INSTALL_DIR
  fi
  
  # Create the files and install them
  make && make install
  
  # Remove not needed files
  cd $BUILD_DIR
  rm -r nginx-$NGINX_V openssl-$OPENSSL_V pcre-$PCRE_V zlib-$ZLIB_V
  
  # Prepare deb package folder structure
  cd hestia-nginx_$HESTIA_V/
  mkdir -p usr/local/hestia etc/init.d DEBIAN
  
  # Download control, postinst and postrm files
  cd DEBIAN
  wget $GIT_REP/nginx/control
  wget $GIT_REP/nginx/copyright
  wget $GIT_REP/nginx/postinst
  wget $GIT_REP/nginx/postrm
  
  # Set permission
  chmod +x postinst postrm
  
  # Move nginx directory
  cd ..
  mv /usr/local/hestia/nginx usr/local/hestia/
  
  # Get service file
  cd etc/init.d
  wget $GIT_REP/nginx/hestia
  chmod +x hestia
  
  # Get nginx.conf
  cd ../../
  rm usr/local/hestia/nginx/conf/nginx.conf
  wget $GIT_REP/nginx/nginx.conf -O usr/local/hestia/nginx/conf/nginx.conf
  
  # Copy binary
  cp usr/local/hestia/nginx/sbin/nginx usr/local/hestia/nginx/sbin/hestia-nginx
  
  # Change permission and build the package
  cd $BUILD_DIR
  chown -R  root:root hestia-nginx_$HESTIA_V
  dpkg-deb --build hestia-nginx_$HESTIA_V
  
  # Remove source folder
  rm -r hestia-nginx_$HESTIA_V
fi

#################################################################################
#
# Building hestia-php
#
#################################################################################

if [ "$PHP_B" = true ] ; then
  # Change to build directory
  cd $BUILD_DIR
  
  # Check if target directory exist
  if [ -d $BUILD_DIR/hestia-php_$HESTIA_V ]; then
  	#mv $BUILD_DIR/hestia-php_$HESTIA_V $BUILD_DIR/hestia-php_$HESTIA_V-$(timestamp)
  	rm -r $BUILD_DIR/hestia-php_$HESTIA_V
  fi
  
  # Create directory
  mkdir $BUILD_DIR/hestia-php_$HESTIA_V
  
  # Download and unpack source files
  wget -qO- $PHP | tar xz
  wget -qO- $OPENSSL | tar xz
  
  # Change to PHP directory
  cd php-$PHP_V
  
  # Configure PHP
  ./configure	--prefix=/usr/local/hestia/php \
              --enable-fpm \
              --with-zlib \
              --with-fpm-user=admin \
              --with-fpm-group=admin \
              --with-openssl=../openssl-$OPENSSL_V \
              --with-mysql \
              --with-mysqli \
              --with-curl \
              --enable-mbstring
  
  # Create the files and install them
  make && make install
  
  # Clear up unused files
  cd $BUILD_DIR
  rm -r php-$PHP_V
  rm -r openssl-$OPENSSL_V
  
  # Prepare deb Package folder structure
  cd hestia-php_$HESTIA_V/
  mkdir -p usr/local/hestia DEBIAN
  
  # Download control, postinst and postrm files
  cd DEBIAN
  wget $GIT_REP/php/control
  wget $GIT_REP/php/copyright
 
  # Move PHP directory
  cd ..
  mv /usr/local/hestia/php usr/local/hestia/
   
  # Get php-fpm.conf
  wget $GIT_REP/php/php-fpm.conf -O usr/local/hestia/php/etc/php-fpm.conf

  # Get php.ini
  wget $GIT_REP/php/php.ini -O usr/local/hestia/php/lib/php.ini  

  # Copy binary
  cp usr/local/hestia/php/sbin/php-fpm usr/local/hestia/php/sbin/hestia-php
  
  # Change permission and build the package
  cd $BUILD_DIR
  chown -R  root:root hestia-php_$HESTIA_V
  dpkg-deb --build hestia-php_$HESTIA_V
  
  # Remove source folder
  rm -r hestia-php_$HESTIA_V
fi

#################################################################################
#
# Building Hestia
#
#################################################################################

if [ "$HESTIA_B" = true ] ; then
  # Change to build directory
  cd $BUILD_DIR
  
  # Check if target directory exist
  if [ -d $BUILD_DIR/hestia_$HESTIA_V ]; then
  	#mv $BUILD_DIR/hestia_$HESTIA_V $BUILD_DIR/hestia_$HESTIA_V-$(timestamp)
  	rm -r $BUILD_DIR/hestia_$HESTIA_V
  fi
  
  # Create directory
  mkdir $BUILD_DIR/hestia_$HESTIA_V
  
  # Download and unpack source files
  wget $HESTIA
  unzip -q master.zip
  rm master.zip
  
  # Prepare deb package folder structure
  cd hestia_$HESTIA_V/
  mkdir -p usr/local/hestia DEBIAN
  
  # Download control, postinst and postrm files
  cd DEBIAN
  wget $GIT_REP/hestia/control
  wget $GIT_REP/hestia/copyright
  wget $GIT_REP/hestia/postinst
  
  # Set permission
  chmod +x postinst
 
  # Move required directories
  cd ../../hestiacp-master
  mv bin func install upd web ../hestia_$HESTIA_V/usr/local/hestia/
   
  # Set permission
  cd ../hestia_$HESTIA_V/usr/local/hestia/bin
  chmod +x *
  
  # Change permission and build the package
  cd $BUILD_DIR
  chown -R root:root hestia_$HESTIA_V
  dpkg-deb --build hestia_$HESTIA_V
  
  # Remove source folder
  rm -r hestia_$HESTIA_V
  rm -r hestiacp-master
fi
