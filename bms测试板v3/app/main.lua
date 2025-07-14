
PROJECT = "BmsTestDevice"
VERSION = "5.0.0"
require "sys"
require "log"
require "pins"
require "modbus"
require "dcbus"
require "operate"
require "pm"
pm.wake("WORK")
require"watchdog"
--  pmd.ldoset(15,pmd.LDO_V_GLOBAL_1V8)




modbus.init()
dcbus.init()
print("init ready")
sys.taskInit(operate.OperaTrace)
sys.taskInit(operate.JudgeOperaResult)
sys.taskInit(operate.DisplayPoll)

rtos.openSoftDog(60*1000)
sys.timerLoopStart(operate.eatSoftDog,50*1000)


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