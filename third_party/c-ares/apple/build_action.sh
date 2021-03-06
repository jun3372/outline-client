#!/bin/bash -e
#
# Copyright 2018 The Outline Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Compile c-ares as a static library for iOS and macOS.

echo "Building libcares..."
pushd $(dirname $0) > /dev/null

SRCDIR="c-ares"
ARCHS="x86_64 armv7 armv7s arm64"

# Copy source from third_party/c-ares
rsync -a --exclude='apple*' .. $SRCDIR

pushd $SRCDIR > /dev/null
./buildconf

for ARCH in $ARCHS
do
  echo "Building $SRCDIR for $ARCH"
  mkdir -p bin/$ARCH

  case $ARCH in
    armv7 | armv7s | arm64 )
      export MINVERSION=9.0
      ;;
    x86_64 )
      export MINVERSION=10.11
      ;;
    * )
      echo "Unsupported architecture $ARCH"
      exit 1
    ;;
  esac

  export PREFIX="`pwd`/bin/$ARCH"
  ../../../../apple/scripts/xconfig.sh $ARCH
  make -j2 && make install
  make clean
done

popd > /dev/null
mkdir -p lib include

# Copy headers
cp -R $SRCDIR/bin/x86_64/include/ include

# Create FAT binary
lipo -output lib/libcares.a -create \
  $SRCDIR/bin/x86_64/lib/libcares.a \
  $SRCDIR/bin/armv7/lib/libcares.a \
  $SRCDIR/bin/armv7s/lib/libcares.a \
  $SRCDIR/bin/arm64/lib/libcares.a

# Clean up
rm -rf $SRCDIR*
popd > /dev/null
