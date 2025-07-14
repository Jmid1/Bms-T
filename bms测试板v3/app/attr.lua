module(..., package.seeall)

require "config"
require "nvm"

-----------------------------------------------------
--
---基础参数
Hw_Ver = 1
Sw_Ver = 0

--
IS_Print = true
------------------

--- attribute 初始化
function init()
    nvm.init("config.lua")
    test_cnt_set(nvm.get("CNTS")) 
end
--
--
--
--
--- 测试个数
local test_cnt = 0
function test_cnt_get() return test_cnt end
function test_cnt_set(data) 
    test_cnt = data 
    if nvm.get("CNTS") ~= data then
        nvm.set("CNTS", data ,nil)
    end
end
--
--- 测试状态
local test_state = false  --false:未测试,true:测试中
function test_state_get() return test_state end
function test_state_set(data) 
    test_state = data 
end
--