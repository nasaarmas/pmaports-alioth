#!/bin/sh


rm -rf ~/Downloads/pmaports-alioth/device-xiaomi-aliothf3 ~/Downloads/pmaports-alioth/firmware-xiaomi-alioth ~/Downloads/pmaports-alioth/linux-xiaomi-aliothf3

cp -r ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/linux-xiaomi-aliothf3 ~/Downloads/pmaports-alioth/linux-xiaomi-aliothf3
cp -r ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/device-xiaomi-aliothf3 ~/Downloads/pmaports-alioth/device-xiaomi-aliothf3
cp -r ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/firmware-xiaomi-alioth ~/Downloads/pmaports-alioth/firmware-xiaomi-alioth

echo "folders replaced"
