{
    --------------------------------------------
    Filename: sensor.temperature.mcp9808.i2c.spin2
    Author: Jesse Burt
    Description: Driver for Microchip MCP9808 temperature sensors
    Copyright (c) 2020
    Started Jul 26, 2020
    Updated Jul 26, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR


OBJ

    i2c : "com.i2c"                                                 ' PASM I2C Driver
    core: "core.con.mcp9808.spin"
    time: "time"

PUB Null{}
''This is not a top-level object

PUB Start(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)        ' I2C object started?
                time.msleep (1)
                if i2c.present (SLAVE_WR)                           ' Response from device?
                    if deviceid == core#DEVID_RESP
                        return okay

    return FALSE                                                    ' If we got here, something went wrong

PUB Stop{}

PUB DeviceID: id
' Read device identification
    readreg(core#MFR_ID, 2, @id.byte[1])
    readreg(core#DEV_ID, 2, @id.byte[0])

PRI readReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
'' read num_bytes from the slave device into the address stored in buff_addr
    case reg_nr                                                     ' Basic register validation
        $00..$08:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg_nr & $0F
            i2c.start{}                                             ' S
            repeat tmp from 0 to 1
                i2c.write (cmd_packet.byte[tmp])                    ' SL|W, reg_nr

            i2c.start{}                                             ' Rs
            i2c.write (SLAVE_RD)                                    ' SL|R
            repeat tmp from 0 to nr_bytes-1
                byte[buff_addr][tmp] := i2c.read(tmp == nr_bytes-1) ' R 0..n, NAK last byte to signal complete
            i2c.stop{}                                              ' P
        OTHER:
            return

PRI writeReg(reg_nr, nr_bytes, buff_addr) | cmd_packet, tmp
'' write num_bytes to the slave device from the address stored in buff_addr
    case reg_nr                                                     ' Basic register validation
        $01..$04, $08:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg_nr & $0F
            i2c.start{}                                             ' S
            repeat tmp from 0 to 1
                i2c.write(cmd_packet.byte[tmp])                     ' SL|W, reg_nr

            repeat tmp from 0 to nr_bytes-1
                i2c.write (byte[buff_addr][tmp])                    ' W 0..n
            i2c.stop{}                                              ' P
        OTHER:
            return


DAT
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
