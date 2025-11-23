# Debugging the Mystery Buzz on Xiaomi Alioth

Lately, I noticed a persistent buzzing coming from my Xiaomi Alioth (SM8250) device. After some investigation, I decided to dig into the kernel, device tree, and system configuration to figure out the source. Here's a step by step account of my debugging process.

TODO: Maybe but break/debug points in systemctl suspend and wake up script to pinpoint the issue.

## 0. Reproducing via Suspend
I verified that the buzz appears after suspend/resume using:
```bash
systemctl suspend -i
```

After waking, the device buzzes once quietly. This strongly points to power rails and DTS configuration, potentially related to edge triggered events (rising vs falling).

## 1. Disabling the Audio Subsystem in DTS

I started by suspecting the audio drivers. The device uses Cirrus Logic CS35L41 amplifiers for the earpiece (RCV) and loudspeaker (LCV). To test if the buzz came from these, I modified the device tree (`sm8250-xiaomi-alioth.dts`) to disable the sound nodes:

```diff
&i2c3 {
-   status = "okay";
+   status = "disabled";
//   cs35l41_rcv: speaker-amp@40 { ... };
//   cs35l41_lcv: speaker-amp@41 { ... };
};

&sound {
//   compatible = "qcom,sm8250-sndcard";
//   model = "xiaomi-alioth";
//   mm1-dai-link { ... };
//   speaker-dai-link { ... };
};
```

I also removed corresponding ALSA configuration sequences that initialize the RCV and LCV devices:

```text
SectionVerb {
    EnableSequence [
        cset "name='RCV DSP1 Preload Switch' 1"
        cset "name='LCV DSP1 Preload Switch' 1"
        ...
    ]
}
```

After rebuilding the kernel and booting, the buzzing persisted. So the sound subsystem was not the culprit.

## 2. Searching for Haptic Devices

Next, I explored `/sys/class` for any haptic or vibration devices. Only the standard input devices were present:

```bash
xiaomi-alioth:/sys/class$ ls -la input/
event0 -> ../../devices/.../pwrkey/input0/event0
event1 -> ../../devices/.../resin/input1/event1
event2 -> ../../devices/.../spi4.0/input2/event2
event3 -> ../../devices/.../gpio-keys/input3/event3
```

Nothing explicitly related to haptics or buzzers appeared.

## 3. Inspecting Kernel Configuration

I then examined the kernel config (`/proc/config.gz`) for any modules related to vibration or buzzers:

```bash
CONFIG_INPUT_PM8XXX_VIBRATOR=m
CONFIG_INPUT_PWM_BEEPER=m
CONFIG_INPUT_PWM_VIBRA=m
```

This indicated that the PM8XXX vibrator and PWM beeper drivers are available, but I couldn’t find them in the device tree.

## 4. Checking Kernel Messages

Finally, I scanned the kernel log for anything mentioning vibration, PWM, haptics, or buzz:

```bash
dmesg | grep -iE "VIB|pwm|haptic|pm8|buzz"
```

The output mostly showed power management and RTC initialization messages. No obvious triggers for a buzzing sound appeared.

## 5. Testing with Disabled RemoteProc

Logs from dmesg during suspend and wakeup suggested issues with remoteproc, but disabling remoteproc completely did not fix the issue.

```bash
xiaomi-alioth:~# echo stop | tee /sys/class/remoteproc/remoteproc0/state
stop
xiaomi-alioth:~# echo stop | tee /sys/class/remoteproc/remoteproc1/state
stop
xiaomi-alioth:~# echo stop | tee /sys/class/remoteproc/remoteproc2/state
stop
```

## 6. Current Status

At this point:

* Audio drivers (CS35L41 amps) are disabled → buzzing still happens.
* ALSA configuration removed → no change.
* No haptic devices found under `/sys/class`.
* Kernel config has PWM/beeper modules, but nothing active at boot.
* `dmesg` logs show only power/RTC messages.
* Buzz appears reliably after suspend/resume.

The buzz is still present. My next steps will likely involve tracing PMIC events and investigating if it could be panel issue.




