#!/bin/sh


rm -rf ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/linux-postmarketos-qcom-sm8250-alioth ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/device-xiaomi-alioth ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/firmware-xiaomi-alioth


cp -r ~/Code/pmaports-alioth/linux-postmarketos-qcom-sm8250-alioth ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/linux-postmarketos-qcom-sm8250-alioth 
cp -r ~/Code/pmaports-alioth/device-xiaomi-alioth ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/device-xiaomi-alioth
cp -r ~/Code/pmaports-alioth/firmware-xiaomi-alioth ~/.local/var/pmbootstrap/cache_git/pmaports/device/testing/firmware-xiaomi-alioth

echo "Updated folder on the computer"
