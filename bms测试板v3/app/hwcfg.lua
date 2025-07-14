
module(..., package.seeall)

RS485_UART_ID = 1 -- 充电柜485串口ID
RS485_DIR = pio.P0_0 -- 充电柜485方向控制IO
RS232_UART_ID = 2

pmd.ldoset(3, pmd.LDO_VLCD)
pmd.ldoset(3,pmd.LDO_VMMC)

 pin24 = pins.setup(pio.P0_24, 0)
 pin27 = pins.setup(pio.P0_27, 0)
 pin28 = pins.setup(pio.P0_28, 0)
 pin25 = pins.setup(pio.P0_25, 0)

 pin14=pins.setup(pio.P0_14, 0)
 pin15=pins.setup(pio.P0_15, 0)

 pin2 =pins.setup(pio.P0_2, 1)
 pin3 =pins.setup(pio.P0_3, 0)
 pin4 =pins.setup(pio.P0_4, 1)
 pin19 =pins.setup(pio.P0_19, 0)

 pin17= pins.setup(pio.P0_17, 1)

 getGpio18Fnc = pins.setup(pio.P0_18)
 getGpio26Fnc = pins.setup(pio.P0_26)


 function Gpio_set_val(v1,v2,v3,v4)

    pin2(v1)
    pin3(v2)
    pin4(v3)
    pin19(v4)

end

 function relay_set_val(v1,v2,v3,v4)

    pin24(v1)
    pin25(v2)
    pin27(v3)
    pin28(v4)

end

