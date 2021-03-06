#!/bin/zsh -f

# LIBJPEG -- http://ijg.org/

scriptpath=$0:A
parentdir=${scriptpath%/*}
scriptname=${scriptpath##*/}

if ! source $parentdir/project_environment.sh; then
  echo "build_libjpeg.sh: error sourcing $parentdir/project_environment.sh"
  exit 1
fi

if [[ -n $1 ]] && [[ $1 == 'clean' ]]; then
  deleted=$(find $ROOT -name '*jpeg*' -prune -print -exec rm -rf {} \;)
  if [[ -n $deleted ]]; then
    echo "$scriptname: deleting..."
    echo $deleted
  else
    echo "$scriptname: clean"
  fi
  exit 0
fi

name='jpegsrc.v9d'

print "\n======== $name ========"

# --  Download / Extract  -----------------------------------------------------

targz=$name.tar.gz
url="http://www.ijg.org/files/$targz"
dirname='jpeg-9d'

download $name $url $targz
extract $name $targz $dirname

# --  Config / Make / Install  ------------------------------------------------

# ios_arm64
export ARCH='arm64'
export TARGET='arm-apple-darwin64'
export PLATFORM='iPhoneOS.platform/Developer/SDKs/iPhoneOS13.6.sdk'
export PLATFORM_MIN_VERSION='-miphoneos-version-min=11.0'

zsh $parentdir/config-make-install_libjpeg.sh $name 'ios_arm64' $dirname || exit 1

# ios_x86_64
export ARCH='x86_64'
export TARGET='x86_64-apple-darwin'
export PLATFORM='iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator13.6.sdk'
export PLATFORM_MIN_VERSION='-mios-simulator-version-min=11.0'

zsh $parentdir/config-make-install_libjpeg.sh $name 'ios_x86_64' $dirname || exit 1

# macos_x86_64
export ARCH='x86_64'
export TARGET='x86_64-apple-darwin'
export PLATFORM='MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk'
export PLATFORM_MIN_VERSION='-mmacosx-version-min=10.13'

zsh $parentdir/config-make-install_libjpeg.sh $name 'macos_x86_64' $dirname || exit 1

# --  Lipo  -------------------------------------------------------------------
xc mkdir -p $ROOT/lib

print -n 'lipo: ios... '
xl $name '5_ios_lipo' \
  xcrun lipo $ROOT/ios_arm64/lib/libjpeg.a $ROOT/ios_x86_64/lib/libjpeg.a \
  -create -output $ROOT/lib/libjpeg.a
print 'done.'

print -n 'lipo: macos... '
xl $name '5_macos_lipo' \
  xcrun lipo $ROOT/macos_x86_64/lib/libjpeg.a \
  -create -output $ROOT/lib/libjpeg-macos.a
print 'done.'

# --  Copy headers  -----------------------------------------------------------

xc mkdir -p $ROOT/include
xc cp $ROOT/ios_arm64/include/j*.h $ROOT/include
