--- 模块功能：电池电压检测驱动
module(..., package.seeall)

require "hw_cfg"

local bat_adc_id = hw_cfg.BAT_ADC_CH
 bat_adc_ctrl = pins.setup(hw_cfg.BAT_ADC_DET_PIN,0)

local flag = 0
local res_1 = 100
local res_2 = 100
local res_3 = 8.2

local buff_size = 32
local buff = {}

--- 电池电压ADC读取
local function adc_read()
    local _, volval = adc.read(bat_adc_id)
    if table.getn(buff) >= buff_size then table.remove(buff, 1) end
    table.insert(buff, volval)
end

--- 电池电压ADC检测打开
function open()
     bat_adc_ctrl(0)
    adc.open(bat_adc_id, adc.SCALE_5V000)--SCALE_1V250

    if flag == 0 then
        flag = 1
        sys.timerLoopStart(adc_read, 10,"Time_Powet")
    end
end

--- 电池电压ADC检测关闭
function close()
    adc.close(bat_adc_id)
    bat_adc_ctrl(0)

    if flag == 1 then
        flag = 0
        sys.timerStop(adc_read,"Time_Powet")
    end
end

--- 电压电压获取
function get()
    local len = table.getn(buff)

    if len >= 3 then
        local buff_ = {}
        for i = 1, len do buff_[i] = buff[i] end
        table.sort(buff_)
        local sum = 0
        local cnt = 0
        for i = math.floor(len / 3), len - math.floor(len / 3) do
            sum = sum + buff_[i]
            cnt = cnt + 1
        end
        sum = sum / cnt
        local vol = sum * (res_1 + res_2 + res_3) / res_3
        vol = vol/1000

        print("adc sample value",vol)
        return vol
    else

        print("adc sample fail !",vol)
        return nil
        
    end
end

