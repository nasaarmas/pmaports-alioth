# Getting Device Tree Source (DTS)
This note documents how I extract readable Device Tree Source (DTS) from Android images and from a running postmarketOS (pmOS) device. It explains the rationale (what is in each image), the tools and commands I used, and a few gotchas I ran into. The goal is to end up with a usable, human readable DTS.

In before Device Tree Blob (DTB) is compiled Device Tree Source (DTS), and final DTB can be created with applying Device Tree Blob Overlay (DTBO) on the DTB.

Ignore `dtc` warnings.

# 1. Dumping DTS from pmOS alioth
We can just use this amazing tool that translates dtb into readable dts:

```dtc -I dtb -O dts -i /boot/sm8250-xiaomi-alioth.dtb /tmp/alioth-mainline.dts```
Where:
 - -I input format
 - -O output format

It creates readable DTS out of DTB. 


# 2. Getting LineageOS DTS from the Images
For comparison I decided to get full dts from lineagOS.
To not flash the phone again I dumped it from the [built images](https://download.lineageos.org/devices/alioth/builds).
As poco f3 started with Android 11, and uses header version 3, it has [vendor boot partition](https://source.android.com/docs/core/architecture/partitions/vendor-boot-partitions).

So basically:
 - **vendor_boot.img**: contains main DTB, can have few version for different phone variants (like EU, GLOBAL, RU etc.) so we need one for our specific device.
 - **dtbo.img**: Contains DTBO, we apply all the overlays as they probably contain overlays for different parts of the DTB.


```bash
 ❯ binwalk vendor_boot.img
DECIMAL                            HEXADECIMAL                        DESCRIPTION

4096                               0x1000                             gzip compressed data, operating system: Unix, timestamp: 1970-01-01 00:00:00, total size: 18908619 bytes
18915328                           0x120A000                          Device tree blob (DTB), version: 17, CPU ID: 0, total size: 477298 bytes
19392626                           0x127E872                          Device tree blob (DTB), version: 17, CPU ID: 0, total size: 477294 bytes
19869920                           0x12F30E0                          Device tree blob (DTB), version: 17, CPU ID: 0, total size: 470376 bytes

```

```bash
 ❯ binwalk dtbo.img                                                                                                                                        
DECIMAL                            HEXADECIMAL                        DESCRIPTION

416                                0x1A0                              Device tree blob (DTB), version: 17, CPU ID: 0, total size: 458105 bytes
458521                             0x6FF19                            Device tree blob (DTB), version: 17, CPU ID: 0, total size: 459753 bytes
918274                             0xE0302                            Device tree blob (DTB), version: 17, CPU ID: 0, total size: 467393 bytes
1385667                            0x1524C3                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 460176 bytes
1845843                            0x1C2A53                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 454590 bytes
2300433                            0x231A11                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 462995 bytes
2763428                            0x2A2AA4                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 461319 bytes
3224747                            0x3134AB                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 451884 bytes
3676631                            0x3819D7                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 462317 bytes
4138948                            0x3F27C4                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 456050 bytes
4594998                            0x461D36                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 458797 bytes
5053795                            0x4D1D63                           Device tree blob (DTB), version: 17, CPU ID: 0, total size: 460783 bytes

```
`binwalk -e` extracted images allowed us to verify which main DTB is right by looking at the msm-id, comparing it to msm-id from the mainline dts.

```bash
 ❯ head alioth-mainline.dts                         
 
/dts-v1/;

/ {
        interrupt-parent = <0x01>;
        #address-cells = <0x02>;
        #size-cells = <0x02>;
        model = "Xiaomi POCO F3";
        compatible = "xiaomi,alioth", "qcom,sm8250";
        chassis-type = "handset";
        qcom,msm-id = <0x164 0x20001>;

```

```bash
❯ head extractions/vendor_boot.img.extracted/120A000/system.dtb

/dts-v1/;

/ {
        model = "Qualcomm Technologies, Inc. kona v2.1 SoC";
        compatible = "qcom,kona";
        qcom,msm-id = <0x164 0x20001>;
        interrupt-parent = <0x01>;
        #address-cells = <0x02>;
        #size-cells = <0x02>;
        qcom,board-id = <0x00 0x00>;

```

Unfortunately `binwalk -e` extracted blobs weren't fully correct. So instead we should use `dd` to be sure that all blobs are of correct size, padding etc. To extract all overlays from the dtbo.img we can use following oneliner:

```bash
binwalk dtbo.img | \
    awk 'NR>5 { print $1 " " $2 " " $14}' | \
    head -n -3 | \
    xargs -n 3 sh -c 'dd if=dtbo.img of=extractions/d"$2".dtb bs=1 skip="$1" count="$3"' _
```
Notes:
 - The awk/column indexes assume the typical binwalk output layout; inspect binwalk output first and adjust fields if your version prints differently.
 - The command writes overlays to extractions/d.dtb (naming by offset helps keep them unique).


Then we need to get final DTB with following tool:
```fdtoverlay -i main_dtb_msm.dtb -o alioth_linageos.dtb extractions/*dtb```

As in previous step we just now need to translate final DTB into DTC:
```dtc -I dtb -O dts alioth_linageos.dtb -o alioth_linageos.dts```

# 3. DTS of LunarisOS for K40

Thanks to @chenxqiyu for sending DTS extracted from his running device.