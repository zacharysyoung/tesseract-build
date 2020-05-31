#! /bin/zsh

scriptname=$0:A
parentdir=${scriptname%/config-make-install_libjpeg.sh}
source $parentdir/project_environment.sh -u || { echo Error sourcing $parentdir/project_environment.sh; exit 1 }

# ARCH='arm64'
# TARGET='arm-apple-darwin64'
# PLATFORM='iPhoneOS.platform/Developer/SDKs/iPhoneOS13.5.sdk'
# PLATFORM_MIN_VERSION='-miphoneos-version-min=11.0'

name=$1     # jpegsrc.v9d
os_arch=$2  # ios_arm64
dirname=$3  # jpeg-9d

print -n "$os_arch: "

pkg_lib=$ROOT/$os_arch/lib/libjpeg.a
if {
    [ -f $pkg_lib ] &&
    info=$(lipo -info $pkg_lib)  &&
    [[ $info =~ 'Non-fat file' ]]  &&
    [[ $info =~ $ARCH ]]
}; then
  print "skipped config/make/install, found valid single-$ARCH-arch $pkg_lib"
  exit 0
fi

cflags=(
  "-arch $ARCH"
  "-isysroot /Applications/Xcode.app/Contents/Developer/Platforms/$PLATFORM"
  $PLATFORM_MIN_VERSION
  "--target=$TARGET"
  \
  '-fembed-bitcode'
  '-no-cpp-precomp'
  '-O2'
  '-pipe'
)

config_flags=(
  CC="$(xcode-select -p)/usr/bin/gcc"
  CXX="$(xcode-select -p)/usr/bin/g++"
  CFLAGS="$cflags"
  CPPFLAGS="$cflags"
  CXXFLAGS="$cflags -Wno-deprecated-register"
  LDFLAGS="-L/Applications/Xcode.app/Contents/Developer/Platforms/$PLATFORM/usr/lib/"
  PKG_CONFIG_PATH="$ROOT/$os_arch/lib/pkgconfig"
  \
  "--host=$TARGET"
  '--enable-shared=no'
  "--prefix=$ROOT/$os_arch"
)

xc mkdir -p $SOURCES/$dirname/$os_arch
xc cd $SOURCES/$dirname/$os_arch

print -n "$os_arch: "

print -n 'configuring... '
xl $name "2_config_$os_arch" ../configure $config_flags || exit 1
print -n 'done, '

print -n 'making... '
xl $name "3_clean_$os_arch" make clean || exit 1
xl $name "3_make_$os_arch" make || exit 1
print -n 'done, '

print -n 'installing... '
xl $name "4_install_$os_arch" make install || exit 1
print 'done.'