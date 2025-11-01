**pmaport for xiaomi poco f3 - alioth**

**Table of Contents**
- [1. Innstallation guide](#1-innstallation-guide)
- [1. Current State](#1-current-state)
- [2. Introduction](#2-introduction)
- [3. Getting the Kernel to Work](#3-getting-the-kernel-to-work)
  - [3.1. Key Config Changes from nikroks defconfig:](#31-key-config-changes-from-nikroks-defconfig)
- [4. Getting UART Logs](#4-getting-uart-logs)
  - [4.1. Finding UART Pins on the PCB](#41-finding-uart-pins-on-the-pcb)
  - [4.2. Reading UART](#42-reading-uart)
  - [4.3. Arduino Code](#43-arduino-code)
  - [4.4. Capturing the Logs](#44-capturing-the-logs)

---
# 1. Innstallation guide

After building the device with systemd:
```
fastboot erase dtbo_b
pmbootstrap flasher flash_rootfs --partition userdata
pmbootstrap flasher flash_kernel --partition boot_b
fastboot set_active b
```

# 1. Current State
Device was built and tested with plasma-mobile UI with systemd.

It works without major issues, most importantly WiFi with `nmtui` is available.

Little cranky at times, TODO:
 - Fix why **the phones needs to be rebooted after flashing** because GUI doesnt want to start
 - Fix `KWindow` as it crashes frequently
 - Verify which defconfig options are needed
 - Enable bluetooth - disabled to enable UART debugging

# 2. Introduction
This phone uses qcom sm8250 CPU and adreno650 GPU, so the port was based on existing postmarketOS work for this chip. Good starting point: [Xiaomi Mi Pad 5 Pro (xiaomi-elish)](https://wiki.postmarketos.org/wiki/Xiaomi_Mi_Pad_5_Pro_(xiaomi-elish))

I also found this [alioth pmaport by nikroks](https://github.com/mainlining/pmaports/tree/nikroks/alioth), but for some reason it crashes straight back to fastboot.

Good guy @Maledict found that defconfig from Mi Pad 5 Pro worked with [linux fork by nikroks](https://github.com/mainlining/linux/tree/nikroks/alioth).

We can call this our starting point.

# 3. Getting the Kernel to Work

The nikroks kernel had potential but needed some config tweaking. Started with the basic setup:
```bash
source envkernel.sh
make defconfig sm8250.config
```
 All changes were made with `make menuconfig`.

First thing - verified that poco's CPU is using 48-bit addressing not 52, and 4 page table levels instead of 5:
- `CONFIG_ARM64_VA_BITS` to 48
- `CONFIG_PGTABLE_LEVELS` to 4

It seems it should also have `CONFIG_ARM64_ERRATUM_2441007=y`, but didn't change it yet.

MMC doesn't seem needed since we only have UFS memory, so disabled `CONFIG_MMC`. Same deal with `CONFIG_ATA`.

Phone has GPU so DRM should work - adreno650 support is there.

## 3.1. Key Config Changes from nikroks defconfig:
```
CONFIG_ARM64_VA_BITS to 48
CONFIG_PGTABLE_LEVELS to 4

changed zstd compression support
changed preempt to none
changed i2c_slave to no
changed null_tty to y

CONFIG_DM_INTEGRITY to y
CONFIG_UDF_FS to y
CONFIG_XFS_FS to y
CONFIG_CRYPTO_MD4 to y
CONFIG_USB_MASS_STORAGE to n
CONFIG_ANDROID_BINDERFS to n
CONFIG_ZRAM_BACKEND_ZSTD to y

!!!! CONFIG_EFI_ZBOOT to n !!!! <-- THE IMPOSTOR
```

*The breakthrough:* After changing `CONFIG_EFI_ZBOOT` to `n`, it started working! Since the phone is missing EFI, this part was never being decompressed - and that was the biggest issue with the config. UART logs showing missing DTB pointed at the decompression issue and further confirms that the phone doesn't have EFI.

# 4. Getting UART Logs

UART logs were configured before the elish defconfig was discovered as working. Because the nikroks defconfig failed pretty early, the only logs visible in early work were **Android BootLoader (ABL) logs**, which is still cool. 

 - Dumps can be found [here](uart_logs).

## 4.1. Finding UART Pins on the PCB

[pmOS wiki for xiaomi poco F3](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_F3_(xiaomi-alioth)) already contains info about UART TX location.

To verify it I looked for the phone schematic on yandex and [found it here](https://vk.com/wall-203976641_3526) (but it can contain viruses, use at your own responsibility).

| ![UART schema](images/uart_pins_schema.png) | ![UART TX PCB](images/uart_tx_pcb.png) |
| ------------------------------------------- | -------------------------------------- |
| _UART pins described on phone's schema_      | _UART TX location on the PCB_          |

We don't really need RX for reading logs. Also according to the PCB schema, RX pin (TP7307) is located on the other side of the PCB which would require disassembling the whole board.

So I decided to solder wire to UART TX pin only, like in this example image from pmOS wiki:
| ![UART TX on alioth PCB](images/Alioth_uart.jpg) |
| ------------------------------------------------ |
| _UART TX marked on the poco F3 PCB_              |

## 4.2. Reading UART

I didn't have a UART to USB-A converter so I had to get creative. Found an _Arduino UNO R3_ which by default communicates with the computer via UART protocol on pins 0 and 1.

**Be careful:** if anything is plugged into pins 0 or 1, flashing can fail. Keep this in mind when uploading code.

**The voltage problem:** After checking with multimeter, the phone's UART works on **1.8V** while Arduino's logic works on **5V** (possibly could work with 3.3V). So I had to design a level shifter from what was available.

In my Arduino kit I found a few [NPN transistors BC547B](https://www.farnell.com/datasheets/410427.pdf) - their specs were fast enough for 115200 bit/s, so I used them to create this level shifter:

| ![level shifter schema](images/level_shifter-schema.png)       |
| -------------------------------------------------------------- |
| _Level shifter with transistors as if connected to the device_ |

Final working connection:
| ![level shifter photo](images/uart_connection_photo.jpeg) |
| --------------------------------------------------------- |
| _Phone connected to the arduino via level shifter_        |

## 4.3. Arduino Code

Simple passthrough from RX to TX:
```cpp
String receivedMessage;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Serial.print("UART adapter begin:\r\n");
}

void loop() {
  while (Serial.available() > 0) {
    char receivedChar = Serial.read();

    if (receivedChar == '\n') {
      Serial.println(receivedMessage);  // Print the received message in the Serial monitor
      receivedMessage = "";  // Reset the received message
    } 
    else {
      receivedMessage += receivedChar;  // Append characters to the received message
    }
  }
}
```

## 4.4. Capturing the Logs

Connect arduino to the computer and listen via `minicom`:
```bash
minicom -b 115200 -D /dev/ttyACM0 -C uart_logs.txt
```

Also needs DTB changes like in the [following patch](linux-postmarketos-qcom-sm8250-alioth/0001-modified-dts-to-see-kernel-data-on-uart.patch).
