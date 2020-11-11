# Original post from https://sourceforge.net/p/openocd/mailman/openocd-devel/thread/20130621135124.GC2326%40home.lan/
# Author Paul Fertser

Hi,

It wasn't the first time I tried and failed to find any guides on
using JTAG for its original purpose, so I felt like trying it on my
own. It's still unclear how to communicate with several different
devices on a chain at the same time as OpenOCD seems to require to
have only one TAP in non-bypass mode at a time.

Here go draft instructions:

1. You need a BSDL file for the components you're using. For STM32s
it's readily available from the vendor's website.

2. From the BSDL file you need to figure out the Boundary Scan
Register Length, e.g. for STM32F100 it's shown in this line:
attribute BOUNDARY_LENGTH of STM32F1_Low_Med_density_value_LQFP64 : entity is 232;

3. It's followed by
attribute BOUNDARY_REGISTER of STM32F1_Low_Med_density_value_LQFP64 : entity is

which describes which bits of BSR correspond to which device's ports.

4. Read the description of the port you're interested in. E.g. PC8
is described by
      "75       (BC_1,  *,              CONTROL,        1),                             " &
      "74       (BC_1,  PC8,            OUTPUT3,        X,      75,     1,      Z),     " &
      "73       (BC_4,  PC8,            INPUT,          X),                             " &          

which means that bit 73 reflects port's input (when it's configured as
input), bit 74 defines port's output (when it's configured as output),
bit 75 sets PC8 to Z-state when set to 1 and to output when set to 0.  

5. Decide on what mode you need: in SAMPLE/PRELOAD mode the buffers
are disconnected from the boundary scan logic and are controlled by
the cpu as usual but you can still sample their values. In EXTEST mode
the buffers are fully controlled by the boundary scan logic. Some SoCs
(including STM32) allow to do boundary scan while SRST is held low,
that makes it impossible for CPU to interfere with the test. You can
control SRST state with "jtag_reset" command.

6. Source manual_bs.tcl (attached) and call "init_bs <bstap>
<bsrlength>". This should be done after "init" call.

7. Proceed with your tests by calling "sample_get_bit_bsr <bitn>" and
other functions from manual_bs.tcl

An example of a semi-automated boundary scan test for an
STM32VLDiscovery board is attached, here follows the log:

$ sudo openocd -f interface/raspberrypi-native.cfg -f target/stm32f1x.cfg -f stm32vldiscovery_bs.tcl 
Open On-Chip Debugger 0.8.0-dev-00011-g7b21292-dirty (2013-05-09-23:11)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.sourceforge.net/doc/doxygen/bugs.html
Info : only one transport option; autoselect 'jtag'
BCM2835 GPIO config: tck = 11, tms = 25, tdi = 10, tdi = 9
adapter speed: 1000 kHz
adapter_nsrst_delay: 100
jtag_ntrst_delay: 100
cortex_m3 reset_config sysresetreq
Info : clock speed 1006 kHz
Info : JTAG tap: stm32f1x.cpu tap/device found: 0x3ba00477 (mfg: 0x23b, part: 0xba00, ver: 0x3)
Info : JTAG tap: stm32f1x.bs tap/device found: 0x06420041 (mfg: 0x020, part: 0x6420, ver: 0x0)
Info : stm32f1x.cpu: hardware has 6 breakpoints, 4 watchpoints


Starting basic STM32VLDiscovery JTAG boundary scan test

All LEDs should be OFF, press Enter

Green LED should be ON, blue LED OFF, press Enter

Green and blue LEDs should be ON, press Enter

Blue LED should be ON, green LED OFF, press Enter

Green and blue LEDs should be ON, do NOT press the USER button, press Enter

Green and blue LEDs should be ON, DO press the USER button, press Enter

Green and blue LEDs should be ON, do NOT press the USER button, press Enter

Green and blue LEDs should be ON, DO press the USER button, press Enter

All tests passed SUCCESSFULLY, exiting
shutdown command invoked

-- 
Be free, use free (http://www.gnu.org/philosophy/free-sw.html) software!
mailto:fercerpav@...
