# Example script to test STM32VLDiscovery with boundary scan
# Original author: Paul Fertser
# Source: https://sourceforge.net/p/openocd/mailman/attachment/20130621135124.GC2326%40home.lan/2/

init

echo "\n\nStarting basic STM32VLDiscovery JTAG boundary scan test\n"

source manual_bs.tcl

init_bs stm32f1x.bs 232
extest_mode
exchange_bsr
echo "All LEDs should be OFF, press Enter"
read stdin 1

# Set PC9 to output 1
set_bit_bsr 72 0
set_bit_bsr_do 71 1
echo "Green LED should be ON, blue LED OFF, press Enter"
read stdin 1

# Set PC8 to output 1
set_bit_bsr 75 0
set_bit_bsr_do 74 1
echo "Green and blue LEDs should be ON, press Enter"
read stdin 1

# Set PC9 to output 0
set_bit_bsr_do 71 0
echo "Blue LED should be ON, green LED OFF, press Enter"
read stdin 1

# Set PC9 to output 1
set_bit_bsr_do 71 1
foreach i {0 1} {
    echo "Green and blue LEDs should be ON, do NOT press the USER button, press Enter"
    read stdin 1
    # Read PA0 state, there's a pulldown on board
    if {[sample_get_bit_bsr 187] == 1} {
	echo "Button is stuck at 1: ERROR, aborting"
	shutdown
	return
    }

    echo "Green and blue LEDs should be ON, DO press the USER button, press Enter"
    read stdin 1
    if {[sample_get_bit_bsr 187] == 0} {
	echo "Button is stuck at 0: ERROR, aborting"
	shutdown
	return
    }
}

echo "All tests passed SUCCESSFULLY, exiting"
shutdown

