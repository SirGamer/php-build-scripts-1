#!/bin/bash
[ -z "$PHP_VERSION" ] && PHP_VERSION="5.6.10"
ZEND_VM="GOTO"
ZLIB_VERSION="1.2.8"
POLARSSL_VERSION="1.3.8"
LIBMCRYPT_VERSION="2.5.8"
GMP_VERSION="6.0.0a"
GMP_VERSION_DIR="6.0.0"
CURL_VERSION="curl-7_41_0"
READLINE_VERSION="6.3"
NCURSES_VERSION="5.9"
PHPNCURSES_VERSION="1.0.2"
#PTHREADS_VERSION="2.0.10"
PTHREADS_VERSION="7d4e30a4cf440a7c25124f95726ef99e587a03b6"
XDEBUG_VERSION="2.2.6"
PHP_POCKETMINE_VERSION="0.0.6"
#UOPZ_VERSION="2.0.4"
WEAKREF_VERSION="0.2.6"
PHPYAML_VERSION="1.1.1"
YAML_VERSION="0.1.4"
#PHPLEVELDB_VERSION="0.1.4"
PHPLEVELDB_VERSION="d84b2ccbe6b879d93cfa3270ed2cc25d849353d5"
#LEVELDB_VERSION="1.18"
LEVELDB_VERSION="b633756b51390a9970efde9068f60188ca06a724" #Check MacOS
LIBXML_VERSION="2.9.1"
LIBPNG_VERSION="1.6.17"
BCOMPILER_VERSION="1.0.2"
echo "[PocketMine] PHP compiler for Linux, MacOS and Android"
DIR="$(pwd)"
date > "$DIR/install.log" 2>&1
#trap "echo \"# \$(eval echo \$BASH_COMMAND)\" >> \"$DIR/install.log\" 2>&1" DEBUG
uname -a >> "$DIR/install.log" 2>&1
echo "[INFO] Checking dependecies"
type make >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"make\""; read -p "Press [Enter] to continue..."; exit 1; }
type autoconf >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"autoconf\""; read -p "Press [Enter] to continue..."; exit 1; }
type automake >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"automake\""; read -p "Press [Enter] to continue..."; exit 1; }
type libtool >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"libtool\""; read -p "Press [Enter] to continue..."; exit 1; }
type m4 >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"m4\""; read -p "Press [Enter] to continue..."; exit 1; }
type wget >> "$DIR/install.log" 2>&1 || type curl >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"wget\" or \"curl\""; read -p "Press [Enter] to continue..."; exit 1; }
type getconf >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"getconf\""; read -p "Press [Enter] to continue..."; exit 1; }
type gzip >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"gzip\""; read -p "Press [Enter] to continue..."; exit 1; }
type bzip2 >> "$DIR/install.log" 2>&1 || { echo >&2 "[ERROR] Please install \"bzip2\""; read -p "Press [Enter] to continue..."; exit 1; }
#Needed to use aliases
shopt -s expand_aliases
type wget >> "$DIR/install.log" 2>&1
if [ $? -eq 0 ]; then
    alias download_file="wget --no-check-certificate -q -O -"
else
    type curl >> "$DIR/install.log" 2>&1
    if [ $? -eq 0 ]; then
        alias download_file="curl --insecure --silent --location"
    else
        echo "error, curl or wget not found"
    fi
fi
#if type llvm-gcc >/dev/null 2>&1; then
#   export CC="llvm-gcc"
#   export CXX="llvm-g++"
#   export AR="llvm-ar"
#   export AS="llvm-as"
#   export RANLIB=llvm-ranlib
#else
    export CC="gcc"
    export CXX="g++"
    #export AR="gcc-ar"
    export RANLIB=ranlib
#fi
COMPILE_FOR_ANDROID=no
HAVE_MYSQLI="--enable-embedded-mysqli --enable-mysqlnd --with-mysqli=mysqlnd"
COMPILE_TARGET=""
COMPILE_CURL="default"
COMPILE_FANCY="no"
HAS_ZEPHIR="no"
IS_CROSSCOMPILE="no"
IS_WINDOWS="no"
DO_OPTIMIZE="no"
DO_STATIC="no"
COMPILE_DEBUG="no"
COMPILE_LEVELDB="no"
FLAGS_LTO=""
if [ $(gcc -dumpversion | sed -e 's/\.\([0-9][0-9]\)/\1/g' -e 's/\.\([0-9]\)/0\1/g' -e 's/^[0-9]\{3,4\}$/&00/') -gt 40800 ]; then
    COMPILE_LEVELDB="yes"
fi
LD_PRELOAD=""
while getopts "::t:oj:srcdlxzff:" OPTION; do
    case $OPTION in
        t)
            echo "[opt] Set target to $OPTARG"
            COMPILE_TARGET="$OPTARG"
            ;;
        j)
            echo "[opt] Set make threads to $OPTARG"
            THREADS="$OPTARG"
            ;;
        r)
            echo "[opt] Will compile readline and ncurses"
            COMPILE_FANCY="yes"
            ;;
        d)
            echo "[opt] Will compile profiler and xdebug"
            COMPILE_DEBUG="yes"
            ;;
        c)
            echo "[opt] Will force compile cURL"
            COMPILE_CURL="yes"
            ;;
        x)
            echo "[opt] Doing cross-compile"
            IS_CROSSCOMPILE="yes"
            ;;
        l)
            echo "[opt] Will compile with LevelDB support"
            COMPILE_LEVELDB="yes"
            ;;
        s)
            echo "[opt] Will compile everything statically"
            DO_STATIC="yes"
            CFLAGS="$CFLAGS -static"
            ;;
        z)
            echo "[opt] Will add PocketMine C PHP extension"
            HAS_ZEPHIR="yes"
            ;;
        f)
            echo "[opt] Enabling abusive optimizations..."
            DO_OPTIMIZE="yes"
            #FLAGS_LTO="-fvisibility=hidden -flto"
            ffast_math="-fno-math-errno -funsafe-math-optimizations -fno-signed-zeros -fno-trapping-math -ffinite-math-only -fno-rounding-math -fno-signaling-nans" #workaround SQLite3 fail
            CFLAGS="$CFLAGS -O2 -DSQLITE_HAVE_ISNAN $ffast_math -ftree-vectorize -fomit-frame-pointer -funswitch-loops -fivopts"
            if [ "$COMPILE_TARGET" != "mac" ] && [ "$COMPILE_TARGET" != "mac32" ] && [ "$COMPILE_TARGET" != "mac64" ]; then
                CFLAGS="$CFLAGS -funsafe-loop-optimizations -fpredictive-commoning -ftracer -ftree-loop-im -frename-registers -fcx-limited-range"
            fi
            
            if [ "$OPTARG" == "arm" ]; then
                CFLAGS="$CFLAGS -mfloat-abi=softfp -mfpu=vfp"
            elif [ "$OPTARG" == "x86_64" ]; then
                CFLAGS="$CFLAGS -mmmx -msse -msse2 -msse3 -mfpmath=sse -free -msahf -ftree-parallelize-loops=4"
            elif [ "$OPTARG" == "x86" ]; then
                CFLAGS="$CFLAGS -mmmx -msse -msse2 -mfpmath=sse -m128bit-long-double -malign-double -ftree-parallelize-loops=4"
            fi
            ;;
        \?)
            echo "Invalid option: -$OPTION$OPTARG" >&2
            exit 1
            ;;
    esac
done
GMP_ABI=""
TOOLCHAIN_PREFIX=""
if [ "$IS_CROSSCOMPILE" == "yes" ]; then
    export CROSS_COMPILER="$PATH"
    if [[ "$COMPILE_TARGET" == "win" ]] || [[ "$COMPILE_TARGET" == "win32" ]]; then
        TOOLCHAIN_PREFIX="i686-w64-mingw32"
        [ -z "$march" ] && march=i686;
        [ -z "$mtune" ] && mtune=pentium4;
        CFLAGS="$CFLAGS -mconsole"
        CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX --target=$TOOLCHAIN_PREFIX --build=$TOOLCHAIN_PREFIX"
        IS_WINDOWS="yes"
        GMP_ABI="32"
        echo "[INFO] Cross-compiling for Windows 32-bit"
    elif [ "$COMPILE_TARGET" == "win64" ]; then
        TOOLCHAIN_PREFIX="x86_64-w64-mingw32"
        [ -z "$march" ] && march=x86_64;
        [ -z "$mtune" ] && mtune=nocona;
        CFLAGS="$CFLAGS -mconsole"
        CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX --target=$TOOLCHAIN_PREFIX --build=$TOOLCHAIN_PREFIX"
        IS_WINDOWS="yes"
        GMP_ABI="64"
        echo "[INFO] Cross-compiling for Windows 64-bit"
    elif [ "$COMPILE_TARGET" == "android" ] || [ "$COMPILE_TARGET" == "android-armv6" ]; then
        COMPILE_FOR_ANDROID=yes
        [ -z "$march" ] && march=armv6;
        [ -z "$mtune" ] && mtune=arm1136jf-s;
        TOOLCHAIN_PREFIX="arm-linux-musleabi"
        CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX --enable-static-link --disable-ipv6"
        CFLAGS="-static $CFLAGS"
        CXXFLAGS="-static $CXXFLAGS"
        LDFLAGS="-static"
        echo "[INFO] Cross-compiling for Android ARMv6"
    elif [ "$COMPILE_TARGET" == "android-armv7" ]; then
        COMPILE_FOR_ANDROID=yes
        [ -z "$march" ] && march=armv7-a;
        [ -z "$mtune" ] && mtune=cortex-a8;
        TOOLCHAIN_PREFIX="arm-linux-musleabi"
        CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX --enable-static-link --disable-ipv6"
        CFLAGS="-static $CFLAGS"
        CXXFLAGS="-static $CXXFLAGS"
        LDFLAGS="-static"
        echo "[INFO] Cross-compiling for Android ARMv7"
    elif [ "$COMPILE_TARGET" == "rpi" ]; then
        TOOLCHAIN_PREFIX="arm-linux-gnueabihf"
        [ -z "$march" ] && march=armv6zk;
        [ -z "$mtune" ] && mtune=arm1176jzf-s;
        if [ "$DO_OPTIMIZE" == "yes" ]; then
            CFLAGS="$CFLAGS -mfloat-abi=hard -mfpu=vfp"
        fi
        CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX"
        [ -z "$CFLAGS" ] && CFLAGS="-uclibc";
        echo "[INFO] Cross-compiling for Raspberry Pi ARMv6zk hard float"
    elif [ "$COMPILE_TARGET" == "mac" ]; then
        [ -z "$march" ] && march=prescott;
        [ -z "$mtune" ] && mtune=generic;
        CFLAGS="$CFLAGS -fomit-frame-pointer";
        TOOLCHAIN_PREFIX="i686-apple-darwin10"
        CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX"
        #zlib doesn't use the correct ranlib
        RANLIB=$TOOLCHAIN_PREFIX-ranlib
        LEVELDB_VERSION="1bd4a335d620b395b0a587b15804f9b2ab3c403f"
        CFLAGS="$CFLAGS -Qunused-arguments -Wno-error=unused-command-line-argument-hard-error-in-future"
        ARCHFLAGS="-Wno-error=unused-command-line-argument-hard-error-in-future"
        GMP_ABI="32"
        echo "[INFO] Cross-compiling for Intel MacOS"
    elif [ "$COMPILE_TARGET" == "ios" ] || [ "$COMPILE_TARGET" == "ios-armv6" ]; then
        [ -z "$march" ] && march=armv6;
        [ -z "$mtune" ] && mtune=arm1176jzf-s;
        TOOLCHAIN_PREFIX="arm-apple-darwin10"
        CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX --target=$TOOLCHAIN_PREFIX -miphoneos-version-min=4.2"
    elif [ "$COMPILE_TARGET" == "ios-armv7" ]; then
        [ -z "$march" ] && march=armv7-a;
        [ -z "$mtune" ] && mtune=cortex-a8;
        TOOLCHAIN_PREFIX="arm-apple-darwin10"
        CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX --target=$TOOLCHAIN_PREFIX -miphoneos-version-min=4.2"
        if [ "$DO_OPTIMIZE" == "yes" ]; then
            CFLAGS="$CFLAGS -mfpu=neon"
        fi
    else
        echo "Please supply a proper platform [android android-armv6 android-armv7 rpi mac ios ios-armv6 ios-armv7 win win32 win64] to cross-compile"
        exit 1
    fi
elif [[ "$COMPILE_TARGET" == "linux" ]] || [[ "$COMPILE_TARGET" == "linux32" ]]; then
    [ -z &q...
