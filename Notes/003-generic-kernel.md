# Moving towards generic sm8250 kernel

Before pushing new device into pmaports it would be a good idea to move towards
generic kernel instead of Nikroks version.

A lot of devices follow this already, so the idea is to have:

* `device-xiaomi-alioth` - for device specific as it needs addresses as well
* `linux-postmarketos-qcom-sm8250` - generic Kernel for all devices using
 that SoC

The plan is to:

1. Build the generic kernel with Nikroks Defconfig and DTS see if it works
2. Start porting device specific drivers from Nikroks Linux (drm, camera etc.)
3. Abandon current defconfig and modify generic's one so it will contain
   necessary options.


## 0. Setup
To get source code of generic kernel:

`git clone git@gitlab.postmarketos.org:soc/qualcomm-sm8250/linux.git`

Build and flash the first time:
```bash
# use envkernel for faster prototyping
source ~/Downloads/pmbootstrap/helpers/envkernel.sh

cp pmaports-alioth/linux-postmarketos-qcom-sm8250-alioth/config-postmarketos-qcom-sm8250-alioth.aarch64 arch/arm64/configs/defconfig

# build the actual kernel
make defconfig -j$(nproc)
make -j$(nproc)

# build package
pmbootstrap build --envkernel linux-postmarketos-qcom-sm8250-alioth
pmbootstrap build device-xiaomi-alioth
pmbootstrap install --password 2358

# flash as in installation guide
pmbootstrap flasher flash_rootfs --partition userdata
pmbootstrap flasher flash_kernel --partition boot_b

fastboot reboot
``` 

For already flashed device we can skip some steps:

```bash
# build the actual kernel
make defconfig -j$(nproc)
make -j$(nproc)

# build package
pmbootstrap build --envkernel linux-postmarketos-qcom-sm8250-alioth

# sideload newly built kernel
pmbootstrap sideload --host 172.16.42.1 --port 22 --user nasarmas --arch aarch64 firmware-xiaomi-alioth

# needs reboot to load sideloaded kernel
sudo reboot now
```

## 1. WIP
Step 1 of plan worked as expected. 
After copying alioth dts and using defconfig from this repo as a base (defconfig) kernel was built correctly and boots up after
flashing. As expected it misses drivers for a few peripherals that is why things like screen don't work.

### 1.1 Porting Drivers
On github we can see which commits were added after fork of the official linus
repo. Based on that I will try to port files that are not already somehow
implemented in generic repo.

List of files worked on already:

* DTS:
    * `arch/arm64/boot/dts/qcom/Makefile`
    * `arch/arm64/boot/dts/qcom/sm8250-xiaomi-alioth.dts`
* Screen Panel:
    * `include/drm/drm_mipi_dsi.h` - changes already present in upstream repo
    * `drivers/gpu/drm/msm/disp/dpu1/dpu_encoder.c` - changes seems obsolete TBC
    * `drivers/gpu/drm/msm/dsi/dsi_host.c` - changes already present in upstream repo
    * `drivers/gpu/drm/panel/Kconfig` - added Kconfig option (implemented)
    * `drivers/gpu/drm/panel/Makefile` - added entry for new panel (implemented)
    * `drivers/gpu/drm/panel/panel-samsung-ams667xx01.c` - copied as is from Nikroks (implemented)
* Touchscreen:
    * `drivers/input/touchscreen/Kconfig` - added Kconfig option (implemented)
    * `drivers/input/touchscreen/Makefile` - added entry for new touchscreen (implemented)
    * `drivers/input/touchscreen/ft8756.c` - copied as is from Nikroks (implemented)
 


