require "pins"

--- 模块功能：硬件接口配置
module(..., package.seeall)
--Z
--
--
-- 
-----------------------------------------------------------------------------
RS485_UART_ID = 1 -- 充电柜485串口ID
RS485_DIR = pio.P0_4 -- 充电柜485方向控制IO
RS232_UART_ID = 2
--
-- 
-----------------------------------------------------------------------------
BAT_ADC_CH = 2 -- 电池ADC通道 2
BAT_ADC_DET_PIN = pio.P0_0 -- 电池ADC测量使能IO  pio.P0_28改为pio.P0_0

DIP_SWITCH_1=pio.P0_2
DIP_SWITCH_2=pio.P0_3

pmd.ldoset(3, pmd.LDO_VLCD)
-- pmd.ldoset(3,pmd.LDO_VMMC)
LED1 = pins.setup(pio.P0_24, 0)
LED2 = pins.setup(pio.P0_25, 0)

-- pins.setup(pio.P0_0, 1)