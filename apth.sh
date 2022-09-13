#!/bin/bash
# bin/compile <build-dir> <cache-dir>
HOMEA=$HOME/linux
STAR0="/lib64:/lib/udev:/lib/systeminfo:/lib/terminfo:/lib:/lib/x86_64-linux-gnu"
STAR1="$HOMEA/lib:$HOMEA/usr/lib:$HOMEA/var/lib:$HOMEA/usr/lib/x86_64-linux-gnu:$HOMEA/lib/x86_64-linux-gnu:$HOMEA/lib:$HOMEA/usr/lib/sudo"
STAR2="$HOMEA/usr/include/x86_64-linux-gnu:$HOMEA/usr/include/x86_64-linux-gnu/bits:$HOMEA/usr/include/x86_64-linux-gnu/gnu"
STAR3="$HOMEA/usr/share/lintian/overrides/:$HOMEA/usr/src/glibc/debian/:$HOMEA/usr/src/glibc/debian/debhelper.in:$HOMEA/usr/lib/mono"
STAR4="$HOMEA/usr/src/glibc/debian/control.in:$HOMEA/usr/lib/x86_64-linux-gnu/libcanberra-0.30:$HOMEA/usr/lib/x86_64-linux-gnu/libgtk2.0-0"
STAR5="$HOMEA/usr/lib/x86_64-linux-gnu/gtk-2.0/modules:$HOMEA/usr/lib/x86_64-linux-gnu/gtk-2.0/2.10.0/immodules:$HOMEA/usr/lib/x86_64-linux-gnu/gtk-2.0/2.10.0/printbackends"
STAR6="$HOMEA/usr/lib/x86_64-linux-gnu/samba/:$HOMEA/usr/lib/x86_64-linux-gnu/pulseaudio:$HOMEA/usr/lib/x86_64-linux-gnu/blas:$HOMEA/usr/lib/x86_64-linux-gnu/blis-serial"
STAR7="$HOMEA/usr/lib/x86_64-linux-gnu/blis-openmp:$HOMEA/usr/lib/x86_64-linux-gnu/atlas:$HOMEA/usr/lib/x86_64-linux-gnu/tracker-miners-2.0:$HOMEA/usr/lib/x86_64-linux-gnu/tracker-2.0:$HOMEA/usr/lib/x86_64-linux-gnu/lapack:$HOMEA/usr/lib/x86_64-linux-gnu/gedit:$HOMEA/usr/lib/x86_64-linux-gnu/xrdp"
STARALL="$STAR0:$STAR1:$STAR2:$STAR3:$STAR4:$STAR5:$STAR6:$STAR7:$STAR8"
PATALL="$HOMEA/bin:$HOMEA/usr/bin:$HOMEA/sbin:$HOMEA/usr/sbin:$HOMEA/etc/init.d:$HOMEA/udocker:$PATH"
echo 'APTH - Application power tool HermiTech 4.2b (goodgamemaga) Russian build'
echo 'This tool will install apps without root'
if ! [ -d $HOME/linux ];
then
echo 'Установка папок'
mkdir $HOME/linux
fi

# fail fast
set -e

# debug
# set -x

# parse and derive params
BUILD_DIR=$HOMEA
CACHE_DIR=$HOMEA/tmp
LP_DIR=`cd $(dirname $0); cd ..; pwd`

function error() {
  echo " !     $*" >&2
  exit 1
}

function topic() {
  echo "-----> $*"
}

function indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";;
    *)      sed -u "$c";;
  esac
}

APT_CACHE_DIR="$CACHE_DIR/apt/cache"
APT_STATE_DIR="$CACHE_DIR/apt/state"
APT_SOURCELIST_DIR="$CACHE_DIR/apt/sources"   # place custom sources.list here

APT_SOURCES="$APT_SOURCELIST_DIR/sources.list"


APT_OPTIONS="-o debug::nolocking=true -o dir::cache=$APT_CACHE_DIR -o dir::state=$APT_STATE_DIR"
APT_OPTIONS="$APT_OPTIONS -o dir::etc::sourcelist=$APT_SOURCES"

rm -rf $APT_CACHE_DIR
mkdir -p "$APT_CACHE_DIR/archives/partial"
mkdir -p "$APT_STATE_DIR/lists/partial"
mkdir -p "$APT_SOURCELIST_DIR"   # make dir for sources
cat "/etc/apt/sources.list" > "$APT_SOURCES"    # no cp here

topic "Updating apt caches"
apt-get $APT_OPTIONS update | indent

for PACKAGE in $*; do
  if [[ $PACKAGE == *deb ]]; then
    PACKAGE_NAME=$(basename $PACKAGE .deb)
    PACKAGE_FILE=$APT_CACHE_DIR/archives/$PACKAGE_NAME.deb

    topic "Fetching $PACKAGE"
    curl -s -L -z $PACKAGE_FILE -o $PACKAGE_FILE $PACKAGE 2>&1 | indent
  else
    topic "Fetching .debs for $PACKAGE"
    apt-get $APT_OPTIONS -y --force-yes -d install --reinstall $PACKAGE | indent
  fi
done

mkdir -p $BUILD_DIR

for DEB in $(ls -1 $APT_CACHE_DIR/archives/*.deb); do
  topic "Installing $(basename $DEB)"
  dpkg -x $DEB $BUILD_DIR
done

topic "Установка завершена"
rm -r $CACHE_DIR/*
find $BUILD_DIR -type f -ipath '*/pkgconfig/*.pc' | xargs --no-run-if-empty -n 1 sed -i -e 's!^prefix=\(.*\)$!prefix='"$BUILD_DIR"'/.\1!g'
echo "SETTING ELEMENTS"