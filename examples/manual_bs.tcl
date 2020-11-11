# Boundary scan commands TCL file for OpenOCD
# Original author: Paul Fertser
# Source: https://sourceforge.net/p/openocd/mailman/attachment/20130621135124.GC2326%40home.lan/1/

# Init global variables to work with the boundary scan register
# the first argument is tap name, the second is BSR length
proc init_bs {tap len} {
    global bsrtap bsrlen
    set bsrtap $tap
    set bsrlen $len
    init_bsrstate
    # disable polling for the cpu TAP as it should be kept in BYPASS 
    poll off
    sample_mode
}

# In this mode BSR doesn't control the outputs but can read the current
# pins' states, the CPU can continue to function normally 
proc sample_mode {} {
    global bsrtap
    # SAMPLE/PRELOAD
    irscan $bsrtap 2
}

# Connect BSR to the boundary scan logic
proc extest_mode {} {
    global bsrtap
    # EXTEST
    irscan $bsrtap 0
}

# Write bsrstateout to target and store the result in bsrstate
proc exchange_bsr {} {
    global bsrtap bsrstate bsrstateout
    update_bsrstate [eval drscan [concat $bsrtap $bsrstateout]]
    return $bsrstate
}

# Check if particular bit is set in bsrstate
proc get_bit_bsr {bit} {
    global bsrstate
    set idx [expr $bit / 32]
    set bit [expr $bit % 32]
    expr ([lindex $bsrstate [expr $idx*2 + 1]] & [expr 2**$bit]) != 0
}

# Resample and get bit
proc sample_get_bit_bsr {bit} {
    exchange_bsr
    get_bit_bsr $bit
}

# Set particular bit to "value" in bsrstateout
proc set_bit_bsr {bit value} {
    global bsrstateout
    set idx [expr ($bit / 32) * 2 + 1]
    set bit [expr $bit % 32]
    set bitval [expr 2**$bit]
    set word [lindex $bsrstateout $idx]
    if {$value == 0} {
	set word [format %X [expr $word & ~$bitval]]
    } else {
	set word [format %X [expr $word | $bitval]]
    }
    set bsrstateout [lreplace $bsrstateout $idx $idx 0x$word]
    return
}

# Set the bit and update BSR on target 
proc set_bit_bsr_do {bit value} {
    set_bit_bsr $bit $value
    exchange_bsr
}

proc init_bsrstate {} {
    global bsrtap bsrlen bsrstate bsrstateout
    set bsrstate ""
    for {set i $bsrlen} {$i > 32} {incr i -32} {
	append bsrstate 32 " " 0xFFFFFFFF " "
    }
    if {$i > 0} {
	append bsrstate $i " " 0xFFFFFFFF
    }
    set bsrstateout $bsrstate
    return
}

proc update_bsrstate {state} {
    global bsrstate
    set i 1
    foreach word $state {
	set bsrstate [lreplace $bsrstate $i $i 0x$word]
	incr i 2
    }
}
