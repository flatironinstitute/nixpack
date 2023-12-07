#!/bin/bash -e

mkdir -p $out/bin
tar -xzf $docker -C $out/bin --strip-components=1
tar -xzf $rootless -C $out/bin --strip-components=1
tar -xzf $rootlesskit -C $out/bin

rm -f $out/bin/dockerd-rootless-setuptool.sh
cp $setupsh $out/bin/dockerd-rootless-setup.sh
