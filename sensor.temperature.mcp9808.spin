{
    --------------------------------------------
    Filename: sensor.temperature.mcp9808.spin
    Author: Jesse Burt
    Description: Driver for Microchip MCP9808 temperature sensors
    Copyright (c) 2022
    Started Jul 26, 2020
    Updated Dec 27, 2022
    See end of file for terms of use.
    --------------------------------------------
}
{ pull in methods common to all Temp drivers }
#include "sensor.temp.common.spinh"

CON

    { I2C }
    SLAVE_WR    = core#SLAVE_ADDR
    SLAVE_RD    = core#SLAVE_ADDR | 1
    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000
    DEF_ADDR    = %000

' Interrupt active states
    LOW         = 0
    HIGH        = 1

VAR

    byte _addr_bits

OBJ

#ifdef MCP9808_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
#define MCP9808_I2C
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.mcp9808"                    ' HW-specific constants
    time: "time"                                ' timekeeping methods

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins, default slave address and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, DEF_ADDR)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O pins and I2C bus speed
    ' validate pins, bus freq, and optional slave address bits:
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ and lookdown(ADDR_BITS: %000..%111)
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            _addr_bits := ADDR_BITS << 1
            time.usleep(core#T_POR)
            ' check device bus presence:
            if (dev_id{} == core#DEVID_RESP)
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}
    _addr_bits := 0

PUB defaults{}
' Factory defaults
    temp_scale(C)
    powered(TRUE)
    temp_res(0_0625)

PUB dev_id{}: id | tmp[2]
' Read device identification
'   Returns:
'       Bits: [15..8]: $0054 (mfr ID), [7..0]: $0400 (rev)
    readreg(core#MFR_ID, 2, @tmp[1])            ' 9808 doesn't support seq. R/W
    readreg(core#DEV_ID, 2, @tmp[0])            '   so do discrete reads
    id.word[1] := tmp[1]
    id.word[0] := tmp[0]

PUB int_clear{} | tmp
' Clear interrupt
    readreg(core#CONFIG, 2, @tmp)
    tmp |= (1 << core#INTCLR)
    writereg(core#CONFIG, 2, @tmp)

PUB int_crit_thresh{}: thresh
' Get critical (high) temperature interrupt threshold
'   Returns: hundredths of a degree Celsius
    thresh := 0
    readreg(core#ALERT_CRIT, 2, @thresh)
    return temp_word2deg(thresh)

PUB int_ena(state): curr_state
' Enable interrupts
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CONFIG, 2, @curr_state)
    case ||state
        0, 1:
            state := ||(state) << core#ALTCNT
        other:
            return (((curr_state >> core#ALTCNT) & 1) == 1)

    state := ((curr_state & core#ALTCNT_MASK) | state)
    writereg(core#CONFIG, 2, @state)

PUB int_hi_thresh{}: thresh
' Get high temperature interrupt threshold
'   Returns: hundredths of a degree Celsius
    thresh := 0
    readreg(core#ALERT_UPPER, 2, @thresh)
    return temp_word2deg(thresh)

PUB int_hyst(deg): curr_setting
' Set interrupt Upper and Lower threshold hysteresis, in degrees Celsius
'   Valid values:
'       Value   represents
'       0       0
'       1_5     1.5C
'       3_0     3.0C
'       6_0     6.0C
'   Any other value polls the chip and returns the current setting
    curr_setting := 0
    readreg(core#CONFIG, 2, @curr_setting)
    case deg
        0, 1_5, 3_0, 6_0:
            deg := lookdownz(deg: 0, 1_5, 3_0, 6_0) << core#HYST
        other:
            curr_setting := (curr_setting >> core#HYST) & core#HYST_BITS
            return lookupz(curr_setting: 0, 1_5, 3_0, 6_0)

    deg := ((curr_setting & core#HYST_MASK) | deg)
    writereg(core#CONFIG, 2, @deg)

PUB int_latch_ena(mode): curr_mode
' Enable interrupt latch
'   Valid values:
'      *FALSE (0) (default): triggered interrupts clear automatically when measurements return
'           inside set thresholds
'       TRUE (-1): triggered interrupts will only be cleared by calling int_clear()
'   Any other value polls the chip and returns the current setting
'   NOTE: This can't be set to TRUE when interrupts are asserted only for crossing the critical
'       threhsold, int_mask() == 1 (hardware limitation)
    curr_mode := 0
    readreg(core#CONFIG, 2, @curr_mode)
    case ||(mode)
        0, 1:
            mode &= 1
        other:
            return (curr_mode & 1)

    mode := ((curr_mode & core#ALTMOD_MASK) | mode)
    writereg(core#CONFIG, 2, @mode)

PUB int_lo_thresh{}: thresh
' Get low temperature interrupt threshold
'   Returns: hundredths of a degree Celsius
    thresh := 0
    readreg(core#ALERT_LOWER, 2, @thresh)
    return temp_word2deg(thresh)

PUB int_mask(mask): curr_mask
' Set interrupt mask
'   Valid values:
'      *0: Interrupts asserted for Upper, Lower, and Critical thresholds
'       1: Interrupts asserted only for Critical threshold
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(core#CONFIG, 2, @curr_mask)
    case mask
        0, 1:
            mask <<= core#ALTSEL
        other:
            return ((curr_mask >> core#ALTSEL) & 1)

    mask := ((curr_mask & core#ALTSEL_MASK) | mask)
    writereg(core#CONFIG, 2, @mask)

PUB int_polarity(state): curr_state
' Set interrupt active state
'   Valid values: *LOW (0), HIGH (1)
'   Any other value polls the chip and returns the current setting
'   NOTE: LOW (Active-low) requires the use of a pull-up resistor
    curr_state := 0
    readreg(core#CONFIG, 2, @curr_state)
    case state
        LOW, HIGH:
            state <<= core#ALTPOL
        other:
            return (curr_state >> core#ALTPOL) & 1

    state := ((curr_state & core#ALTPOL_MASK) | state)
    writereg(core#CONFIG, 2, @state)

PUB int_set_crit_thresh(thresh)
' Set critical (high) temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C; clamped to range)
    thresh := calc_temp_word(-256_00 #> thresh <# 255_94)
    writereg(core#ALERT_CRIT, 2, @thresh)

PUB int_set_hi_thresh(thresh)
' Set high temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C; clamped to range)
    thresh := calc_temp_word(-256_00 #> thresh <# 255_94)
    writereg(core#ALERT_UPPER, 2, @thresh)

PUB int_set_lo_thresh(thresh)
' Set low temperature interrupt threshold, in hundredths of a degree Celsius
'   Valid values: -256_00..255_94 (-256.00C .. 255.94C)
    thresh := calc_temp_word(-256_00 #> thresh <# 255_94)
    writereg(core#ALERT_LOWER, 2, @thresh)

PUB interrupt{}: active_ints
' Flag indicating interrupt(s) asserted
'   Returns: 3-bit mask, [2..0]
'       2: Temperature at or above Critical threshold
'       1: Temperature above high threshold
'       0: Temperature below low threshold
    readreg(core#TEMP, 2, @active_ints)
    active_ints >>= 13

PUB powered(state): curr_state
' Enable sensor power
'   Valid values: *TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CONFIG, 2, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) << core#SHDN
        other:
            return ((((curr_state >> core#SHDN) & 1) ^ 1) == 1)

    state := ((curr_state & core#SHDN_MASK) | state)
    writereg(core#CONFIG, 2, @state)

PUB temp_data{}: temp_adc
' Read temperature ADC data
'   Returns: s13
    temp_adc := 0
    readreg(core#TEMP, 2, @temp_adc)

PUB temp_res(deg_c): curr_res
' Set temperature resolution, in degrees Celsius (fractional)
'   Valid values:
'       Value   represents      Conversion time
'      *0_0625  0.0625C         (250ms)
'       0_1250  0.125C          (130ms)
'       0_2500  0.25C           (65ms)
'       0_5000  0.5C            (30ms)
'   Any other value polls the chip and returns the current setting
    case deg_c
        0_0625, 0_1250, 0_2500, 0_5000:
            deg_c := lookdownz(deg_c: 0_5000, 0_2500, 0_1250, 0_0625)
            writereg(core#RESOLUTION, 1, @deg_c)
        other:
            curr_res := 0
            readreg(core#RESOLUTION, 1, @curr_res)
            return lookupz(curr_res: 0_5000, 0_2500, 0_1250, 0_0625)

PUB temp_word2deg(temp_word): temp | whole, part
' Convert temperature ADC word to temperature
'   Returns: temperature, in hundredths of a degree, in chosen scale
    temp_word := (temp_word << 19) ~> 19        ' Extend sign bit (#12)
    whole := (temp_word / 16) * 100             ' Scale up to hundredths
    part := ((temp_word // 16) * 0_0625) / 100
    temp := (whole + part)
    case _temp_scale
        C:
            return temp
        F:
            return ((temp * 9_00) / 5_00) + 32_00
        other:
            return FALSE

PRI calc_temp_word(temp_c): temp_word
' Calculate word, given temperature in degrees Celsius
'   Returns: 11-bit, two's complement word (0.25C resolution)
    temp_word := 0
    if (temp_c < 0)
        temp_word := temp_c + 256_00
    else
        temp_word := temp_c

    temp_word := ((temp_word * 4) << 2) / 100

    if (temp_c < 0)
        temp_word |= constant(1 << 12)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the slave device into ptr_buff
    case reg_nr                                 ' validate reg number
        $00..$08:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)

            i2c.start{}
            i2c.write(SLAVE_RD | _addr_bits)
            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the slave device from ptr_buff
    case reg_nr
        $01..$04, $08:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr & $0F
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_msbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

