# Simple intro into Kernel Modules

For development there is no need to compile driver directly with kernel.

There is option to compile **out-of-tree Linux Kernel Modules**. So we can
either try to compile on the PC using for example `envkernel`. Or directly on
the phone if it is functional already.

## 1. Compiling on the phone

1. Install necessary packages for compilation: \
    `sudo apk add rsync make clang lld flex bison llvm perl findutils
    openssl-dev`
2. Copy kernel source code to the device (`rsync` >> `scp`): \
    `rsync -a --info=progress2 Code/linux/ nasarmas@172.16.42.1:/home/nasarmas/Downloads/`
3. Make proper link to compiled headers for _Makefile_: \
   `sudo ln -sfn /home/nasarmas/Downloads/.output /lib/modules/6.19.6-pipa/build` 
4. Clean the repo, can't hurt to be sure it is in correct state: \
    `make -j$(nproc) mrproper`
5. Copy used kernel config: \
    `cp /boot/config .config`
6. Verify config: \
    `make LLVM=1 -j$(nproc) olddefconfig`
7. Prepare modules: \
    `make LLVM=1 -j$(nproc) modules_prepare`
8. Last thing needed is _Module.symvers_ for exported symbols, copy it from the
   PC: \
    `scp .output/Module.symvers nasarmas@172.16.42.1:/home/nasarmas/Downloads/` \
    or build the whole kernel (takes 1.5h): \
    `make LLVM=1 -j$(nproc)`




## WIKI

* What is _**Module.symvers**_? - _**Module.symvers**_ is a file generated during the kernel build process. It contains a list of all the exported symbols from the kernel or other modules. These symbols represent functions, variables, or structures that can be accessed by other modules. This file is primarily used to track symbol versions and ensure that modules correctly link to each other.

