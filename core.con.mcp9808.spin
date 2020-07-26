{
    --------------------------------------------
    Filename: core.con.mcp9808.spin2
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Jul 26, 2020
    Updated Jul 26, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ    = 400_000
    SLAVE_ADDR      = $18 << 1

'' Register definitions
    RFU             = $00           ' R/O
    CONFIG          = $01           ' R/W
    ALERT_UPPER     = $02           ' R/W
    ALERT_LOWER     = $03           ' R/W
    TEMP_CRIT       = $04           ' R/W
    TEMP            = $05           ' R/O
    MFR_ID          = $06           ' R/O
    DEV_ID          = $07           ' R/O
        DEVID_RESP  = $0054_0400    ' Expected response: MFR_DEV
    RESOLUTION      = $08           ' R/W

#ifndef __propeller2__
PUB Null
'' This is not a top-level object
#endif

{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
