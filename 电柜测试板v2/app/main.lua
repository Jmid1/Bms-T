
PROJECT = "CAN_TEST"
VERSION = "1.0.0"
require "sys"
require "log"
require "pins"
-- local can = require "can"
-- local xl2515=require"xl2515"
require "bat_voltage"
require "can"
require "com_process"
require "lcd"
require "operate"
require "pm"
pm.wake("WORK")
--  pmd.ldoset(15,pmd.LDO_V_GLOBAL_1V8)

bat_voltage.open()
can.init()
com_process.init()
lcd.init()
print("init ready")
sys.taskInit(operate.OperaTrace)
sys.taskInit(operate.JudgeResult)
sys.taskInit(operate.DisplayPoll)

sys.taskInit(operate.CloseCharger)

-- sys.taskInit(function()
--     while true do            
--         -- xl2515.send_buffer({id = 0x7FF,ide = false,rtr = false},0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07)
--         -- print("can is running")
--         -- bat_voltage.get()
--         sys.wait(500)
--     end
-- end)



sys.init(0, 0)
sys.run()