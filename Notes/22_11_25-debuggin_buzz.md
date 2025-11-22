# Debugging the Mystery Buzz on Xiaomi Alioth

Lately, I noticed a persistent buzzing coming from my Xiaomi Alioth (SM8250) device. After some investigation, I decided to dig into the kernel, device tree, and system configuration to figure out the source. Here's a step-by-step account of my debugging process.

## Step 1: Disabling the Audio Subsystem in DTS

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

## Step 2: Searching for Haptic Devices

Next, I explored `/sys/class` for any haptic or vibration devices. Only the standard input devices were present:

```bash
xiaomi-alioth:/sys/class$ ls -la input/
event0 -> ../../devices/.../pwrkey/input0/event0
event1 -> ../../devices/.../resin/input1/event1
event2 -> ../../devices/.../spi4.0/input2/event2
event3 -> ../../devices/.../gpio-keys/input3/event3
```

Nothing explicitly related to haptics or buzzers appeared.

## Step 3: Inspecting Kernel Configuration

I then examined the kernel config (`/proc/config.gz`) for any modules related to vibration or buzzers:

```bash
CONFIG_INPUT_PM8XXX_VIBRATOR=m
CONFIG_INPUT_PWM_BEEPER=m
CONFIG_INPUT_PWM_VIBRA=m
```

This indicated that the PM8XXX vibrator and PWM beeper drivers are available, but I couldn’t find them in the device tree.

## Step 4: Checking Kernel Messages

Finally, I scanned the kernel log for anything mentioning vibration, PWM, haptics, or buzz:

```bash
dmesg | grep -iE "VIB|pwm|haptic|pm8|buzz"
```

The output mostly showed power management and RTC initialization messages. No obvious triggers for a buzzing sound appeared.

## Current Status

At this point:

* Audio drivers (CS35L41 amps) are disabled → buzzing still happens.
* ALSA configuration removed → no change.
* No haptic devices found under `/sys/class`.
* Kernel config has PWM/beeper modules, but nothing active at boot.
* `dmesg` logs show only power/RTC messages.

The buzz is still present. My next steps will likely involve tracing PMIC events and investigating if it could be panel issue.


