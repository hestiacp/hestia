# Autocompile Script for HestiaCP deb Files.

# Set compiling directory
BUILD_DIR='/tmp/hestiacp-src/'
DEB_DIR="$BUILD_DIR/debs/"
INSTALL_DIR='/usr/local/hestia'

# Set Version for compiling
HESTIA_V='0.9.8-29_amd64'
NGINX_V='1.16.0'
OPENSSL_V='1.1.1b'
PCRE_V='8.43'
ZLIB_V='1.2.11'
PHP_V='7.3.4'

# Create build directories
rm -rf $BUILD_DIR
mkdir -p $DEB_DIR

# Set package dependencies for compiling
SOFTWARE='build-essential libxml2-dev libz-dev libcurl4-gnutls-dev unzip openssl libssl-dev pkg-config'

# Define a timestamp function
timestamp() {
    date +%s
}

branch=$2
install=$3

# Set install flags
if [ ! -z "$2" ]; then
  branch=$2
else
  echo -n "Please enter the name of the branch to build from (e.g. master): "
  read branch
fi

if [ ! -z "$3" ]; then
  install=$3
else
  echo -n 'Would you like to install the compiled packages? [y/N] '
  read install
fi
install=$(echo "$install" | tr '[:upper:]' '[:lower:]')

# Install needed software
echo "Updating system APT repositories..."
apt-get -qq update > /dev/null 2>&1
echo "Installing dependencies for compilation..."
apt-get -qq install -y $SOFTWARE > /dev/null 2>&1

# Fix for Debian PHP Envroiment
if [ ! -e /usr/local/include/curl ]; then
    ln -s /usr/include/x86_64-linux-gnu/curl /usr/local/include/curl
fi

# Get system cpu cores
NUM_CPUS=$(grep "^cpu cores" /proc/cpuinfo | uniq |  awk '{print $4}')

# Set packages to compile
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
  echo "ERROR: Invalid compilation flag specified. Valid flags include:"
  echo "--all:      Build all hestia packages."
  echo "--hestia:   Build only the Control Panel package."
  echo "--nginx:    Build only the backend nginx engine package."
  echo "--php:      Build only the backend php engine package"
  echo ""
  echo "For automated builds and installatioms, you may specify the branch"
  echo "after one of the above flags. To install the packages, specify 'Y'"
  echo "following the branch name."
  echo ""
  echo "Example: bash hst_autocompile.sh --hestia develop Y"
  echo "This would install a Hestia Control Panel package compiled with the"
  echo "develop branch code."
  exit 1
fi

# Set git repository raw path
GIT_REP='https://raw.githubusercontent.com/hestiacp/hestiacp/'$branch'/src/deb'

# Generate Links for sourcecode
HESTIA='https://github.com/hestiacp/hestiacp/archive/'$branch'.zip'
NGINX='https://nginx.org/download/nginx-'$NGINX_V'.tar.gz'
OPENSSL='https://www.openssl.org/source/openssl-'$OPENSSL_V'.tar.gz'
PCRE='https://ftp.pcre.org/pub/pcre/pcre-'$PCRE_V'.tar.gz'
ZLIB='https://www.zlib.net/zlib-'$ZLIB_V'.tar.gz'
PHP='http://de2.php.net/distributions/php-'$PHP_V'.tar.gz'


#################################################################################
#
# Building hestia-nginx
#
#################################################################################

if [ "$NGINX_B" = true ] ; then

    echo "Building Nginx"
    # Change to build directory
    cd $BUILD_DIR

    # Check if target directory exist
    if [ -d $BUILD_DIR/hestia-nginx_$NGINX_V ]; then
          #mv $BUILD_DIR/hestia-nginx_$NGINX_V $BUILD_DIR/hestia-nginx_$NGINX_V-$(timestamp)
          rm -r $BUILD_DIR/hestia-nginx_$NGINX_V
    fi

    # Create directory
    mkdir $BUILD_DIR/hestia-nginx_$NGINX_V

    # Download and unpack source files
    wget -qO- $NGINX | tar xz
    wget -qO- $OPENSSL | tar xz
    wget -qO- $PCRE | tar xz
    wget -qO- $ZLIB | tar xz

    # Change to nginx directory
    cd nginx-$NGINX_V

    # configure nginx
    ./configure   --prefix=/usr/local/hestia/nginx \
                  --with-http_ssl_module \
                  --with-openssl=../openssl-$OPENSSL_V \
                  --with-openssl-opt=enable-ec_nistp_64_gcc_128 \
                  --with-openssl-opt=no-nextprotoneg \
                  --with-openssl-opt=no-weak-ssl-ciphers \
                  --with-openssl-opt=no-ssl3 \
                  --with-pcre=../pcre-$PCRE_V \
                  --with-pcre-jit \
                  --with-zlib=../zlib-$ZLIB_V

    # Check install directory and remove if exists
    if [ -d "$BUILD_DIR$INSTALL_DIR" ]; then
          rm -r "$BUILD_DIR$INSTALL_DIR"
    fi

    # Create the files and install them
    make -j $NUM_CPUS && make DESTDIR=$BUILD_DIR install

    # Cleare up unused files
    cd $BUILD_DIR
    rm -r nginx-$NGINX_V openssl-$OPENSSL_V pcre-$PCRE_V zlib-$ZLIB_V

    # Prepare Deb Package Folder Structure
    cd hestia-nginx_$NGINX_V/
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
    mv $BUILD_DIR/usr/local/hestia/nginx usr/local/hestia/

    # Get Service File
    cd etc/init.d
    wget $GIT_REP/nginx/hestia
    chmod +x hestia

    # Get nginx.conf
    cd ../../
    rm usr/local/hestia/nginx/conf/nginx.conf
    wget $GIT_REP/nginx/nginx.conf -O usr/local/hestia/nginx/conf/nginx.conf

    # copy binary
    cp usr/local/hestia/nginx/sbin/nginx usr/local/hestia/nginx/sbin/hestia-nginx

    # change permission and build the package
    cd $BUILD_DIR
    chown -R  root:root hestia-nginx_$NGINX_V
    dpkg-deb --build hestia-nginx_$NGINX_V
    mv *.deb $DEB_DIR

    # clear up the source folder
    rm -r hestia-nginx_$NGINX_V
fi


#################################################################################
#
# Building hestia-php
#
#################################################################################

if [ "$PHP_B" = true ] ; then
    echo "Building PHP"
    # Change to build directory
    cd $BUILD_DIR

    # Check if target directory exist
    if [ -d $BUILD_DIR/hestia-php_$PHP_V ]; then
          #mv $BUILD_DIR/hestia-php_$PHP_V $BUILD_DIR/hestia-php_$PHP_V-$(timestamp)
          rm -r $BUILD_DIR/hestia-php_$PHP_V
    fi

    # Create directory
    mkdir ${BUILD_DIR}/hestia-php_$PHP_V

    # Download and unpack source files
    wget -qO- $PHP | tar xz

    # Change to php directory
    cd php-$PHP_V

    # Configure PHP
    ./configure   --prefix=/usr/local/hestia/php \
                --enable-fpm \
                --with-fpm-user=admin \
                --with-fpm-group=admin \
                --with-libdir=lib/x86_64-linux-gnu \
                --with-mysqli \
                --with-curl \
                --enable-mbstring

    # Create the files and install them
    make -j $NUM_CPUS && make INSTALL_ROOT=$BUILD_DIR install

    # Cleare up unused files
    cd $BUILD_DIR
    rm -r php-$PHP_V

    # Prepare Deb Package Folder Structure
    cd hestia-php_$PHP_V/
    mkdir -p usr/local/hestia DEBIAN

    # Download control, postinst and postrm files
    cd DEBIAN
    wget $GIT_REP/php/control
    wget $GIT_REP/php/copyright

    # Move php directory
    cd ..
    mv ${BUILD_DIR}/usr/local/hestia/php usr/local/hestia/

    # Get php-fpm.conf
    wget $GIT_REP/php/php-fpm.conf -O usr/local/hestia/php/etc/php-fpm.conf

    # Get php.ini
    wget $GIT_REP/php/php.ini -O usr/local/hestia/php/lib/php.ini

    # copy binary
    cp usr/local/hestia/php/sbin/php-fpm usr/local/hestia/php/sbin/hestia-php

    # change permission and build the package
    cd $BUILD_DIR
    chown -R  root:root hestia-php_$PHP_V
    dpkg-deb --build hestia-php_$PHP_V
    mv *.deb $DEB_DIR

    # clear up the source folder
    rm -r hestia-php_$PHP_V
fi


#################################################################################
#
# Building hestia
#
#################################################################################

if [ "$HESTIA_B" = true ] ; then
    echo "Building Hestia"
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
    unzip -q $branch.zip
    rm $branch.zip

    # Prepare Deb Package Folder Structure
    cd hestia_$HESTIA_V/
    mkdir -p usr/local/hestia DEBIAN

    # Download control, postinst and postrm files
    cd DEBIAN
    wget $GIT_REP/hestia/control
    wget $GIT_REP/hestia/copyright
    wget $GIT_REP/hestia/postinst

    # Set permission
    chmod +x postinst

    # Move needed directories
    cd ../../hestiacp-$branch
    mv bin func install web ../hestia_$HESTIA_V/usr/local/hestia/

    # Set permission
    cd ../hestia_$HESTIA_V/usr/local/hestia/bin
    chmod +x *

    # change permission and build the package
    cd $BUILD_DIR
    chown -R root:root hestia_$HESTIA_V
    dpkg-deb --build hestia_$HESTIA_V
    mv *.deb $DEB_DIR

    # clear up the source folder
    rm -r hestia_$HESTIA_V
    rm -r hestiacp-$branch
fi


#################################################################################
#
# Install Packages
#
#################################################################################

if [ "$install" = 'yes' ] || [ "$install" = 'y' ]; then
    echo "Installing packages"
    for i in $DEB_DIR/*.deb; do
      # Install all available packages
      dpkg -i $i
    done
    unset $answer
fi
