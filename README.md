# pmaport for xiaomi poco f3 - alioth


Basically steps taken:

```
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

make defconfig
./scripts/kconfig/merge_config.sh .config arch/arm64/configs/sm8250.config

```
