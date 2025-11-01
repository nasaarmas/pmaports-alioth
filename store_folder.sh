#!/bin/sh


rm -rf ~/Code/pmaports-alioth/device-xiaomi-alioth ~/Code/pmaports-alioth/firmware-xiaomi-alioth ~/Code/pmaports-alioth/linux-postmarketos-qcom-sm8250-alioth

cp -r ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/linux-postmarketos-qcom-sm8250-alioth ~/Code/pmaports-alioth/linux-postmarketos-qcom-sm8250-alioth
cp -r ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/device-xiaomi-alioth ~/Code/pmaports-alioth/device-xiaomi-alioth
cp -r ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/firmware-xiaomi-alioth ~/Code/pmaports-alioth/firmware-xiaomi-alioth

echo "Folders replaced in the repo"
