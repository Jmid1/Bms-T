module(..., package.seeall)
require "serial"
require "items"
require "operate"
require "lcd"
require "can"
local serial_rs485 = serial.new(serial.Interface_Type.RS485,hw_cfg.RS485_UART_ID,9600,hw_cfg.RS485_DIR)

Bat_Rs485_Tab = {}
Bat_Rs485_Tab.Rs485="NG"
Bat_Rs485_Tab.IMEI="NG"
Bat_Rs485_Tab.Signal="NG"
Bat_Rs485_Tab.SOC="NG"
Bat_Rs485_Tab.SOE="NG"
Bat_Rs485_Tab.IOC="NG"
Bat_Rs485_Tab.Cell_Max_Volt="NG"
Bat_Rs485_Tab.Cell_Min_Volt="NG"
Bat_Rs485_Tab.Cell_Dif_Volt="NG"
Bat_Rs485_Tab.Charge_Current="NG"
Bat_Rs485_Tab.Bee="NG"
Bat_Rs485_Tab.Num="NG"
Bat_Rs485_Tab.Volt="NG"

MinVoltNumber=0
MaxVoltNumber=0

AnalogData={}
AnalogData.type=0
AnalogData.len=0
AnalogData.adr=0
volt_table = {}

local function bubbleSort(arr)

    local n = #arr
    local min=9999
    local max=0
    local imin=0
    local imax=0
    -- local temp
    -- 外层循环控制排序轮数
    -- for i = 1, n - 1 do
    --     -- 内层循环比较相邻元素
    --     for j = 1, n - i do
    --         -- 如果前一个元素比后一个大，则交换它们
    --         if arr[j] > arr[j + 1] then
    --             arr[j], arr[j + 1] = arr[j + 1], arr[j]
    --         end

    --     end
    -- end
    -- min=arr[1]
    -- max=arr[#arr]
   for i = 1, n do
        if max< arr[i] then
            max=arr[i]
            imax=i
        end
   end
   for i = 1, n do
        if min>arr[i] then
            min=arr[i]
            imin=i
        end
   end
   return min,max,imin,imax
end

local function hex_to_string(hex_table)
    local result = ""
    for _, hex in ipairs(hex_table) do
        -- 将十六进制数转换为字符并拼接到结果字符串中
        result = result .. string.format("%02X", hex)
    end
    -- 去掉前导的 "08" 和 "08"
    result = result:gsub("%d", "",7)
    result = result:sub(1,-5)
    return result
end


local function recv_data_process()
  
    local byte = {}
    local buff = serial_rs485:get_recv()
    for i = 1, #buff do
        if not buff[i] then return end
        byte[i] = string.byte(buff[i])
    end
    
    if  byte[1]==1 or byte[1]==0 then
       if byte[2]==1 or byte[2]==3 or byte[2]==4 or byte[2]==5 then
        local crc_buf = table.concat(buff)
        local crc16 = crypto.crc16("MODBUS",crc_buf:sub(1,-3))
        local crc_new = byte[#byte-1]+ byte[#byte]*256
        if crc16==crc_new then
           
            --print("CRC485数据校验正常")
            local len = byte[3]
           if lcd.KeyStatus==1 then

                if items.items_tab[lcd.OpreaIndex].name=="Rs485" then
                    Bat_Rs485_Tab.Num  = byte[6]*256+byte[7]
                    Bat_Rs485_Tab.Volt = byte[4]*256+byte[5]
                -- Bat_Rs485_Tab.Rs485 = "OK"
                elseif items.items_tab[lcd.OpreaIndex].name=="IMEI" then
                    Bat_Rs485_Tab.IMEI = hex_to_string(byte)
                elseif items.items_tab[lcd.OpreaIndex].name=="Signal" then
                    Bat_Rs485_Tab.Signal =  byte[5]
                elseif items.items_tab[lcd.OpreaIndex].name=="SOC" then
                    Bat_Rs485_Tab.SOC = byte[4]*256+byte[5]
                elseif  items.items_tab[lcd.OpreaIndex].name=="SOE" then
                    Bat_Rs485_Tab.SOE = byte[4]*256+byte[5]
                elseif  items.items_tab[lcd.OpreaIndex].name=="IOC" then
                    Bat_Rs485_Tab.IOC = byte[4]*256+byte[5]
                elseif  items.items_tab[lcd.OpreaIndex].name=="Cell_Min_Volt" then
                    volt_table = {}
                    for i=1,Bat_Rs485_Tab.Num do
                        local LowBit  = i*2+2
                        local HighBit = i*2+3
                        if i>20 then 
                            LowBit=LowBit+2
                            HighBit=HighBit+2
                        end
                        volt_table[i] = byte[LowBit]*256+byte[HighBit] 
                    end
                    Bat_Rs485_Tab.Cell_Min_Volt,Bat_Rs485_Tab.Cell_Max_Volt,MinVoltNumber,MaxVoltNumber = bubbleSort(volt_table)
                    Bat_Rs485_Tab.Cell_Dif_Volt = Bat_Rs485_Tab.Cell_Max_Volt-Bat_Rs485_Tab.Cell_Min_Volt
                    volt_table[Bat_Rs485_Tab.Num+1]=Bat_Rs485_Tab.Cell_Min_Volt
                    print("最大最小电压",Bat_Rs485_Tab.Cell_Min_Volt,Bat_Rs485_Tab.Cell_Max_Volt,MinVoltNumber,MaxVoltNumber)
                elseif items.items_tab[lcd.OpreaIndex].name=="Charge_Current" then
                    Bat_Rs485_Tab.Charge_Current = -(byte[4]*256+byte[5]-0x10000)
                    -- print("电流数据接收")
                end 

            elseif lcd.KeyStatus==2 or lcd.KeyStatus==3 then

                if lcd.OpreateStart==1 then
                    local RegAdr=byte[3]*256+byte[4]
                    local RegLen=byte[5]*256+byte[6]
                    if RegAdr==0 and (RegLen==4 or RegLen==7) then
                        sys.publish("SeekAnalog")
                    elseif RegAdr==0x3E8 and RegLen==0x0D  then
                        --生成随机码
                        sys.publish("SeekBtcode")
                    elseif RegAdr==0x01 and RegLen==0x03  then
                         if items.items_tab[lcd.OpreaIndex].name=="Charger485" then
                           sys.publish("SeekCharger")
                         end
                    end
                end
            end
        end

       end
       
    end
end




 function modbus_frame_send(cmd,adr,len)

    local buf={}
    buf[1]=0x01
    buf[2]=cmd
    buf[3]=bit.band(bit.rshift(adr,8),0xFF)
    buf[4]=bit.band(adr,0xFF)
    buf[5]=bit.band(bit.rshift(len,8),0xFF)
    buf[6]=bit.band(len,0xFF)
    local crc_buf=string.char(unpack(buf))    
    local crc16 = crypto.crc16("MODBUS",string.sub(crc_buf,1,-1))
    buf[7]=crc16%256
    buf[8]=bit.band(crc16,0xFF00)/256
    serial_rs485:send(buf)
    
 end

  function Analog_Data_Send(cmd,len,adr)
    local analog_list={}
    local data={}
    if adr~=0x3E8 and len<=9 and cmd==3 then
    local vol,elecnt,power,actual_cap,temp=3510,24,98,98,28
    analog_list[1] = bit.band(bit.rshift(vol, 8), 0xFF) -- 总电压
    analog_list[2] = bit.band(vol, 0xFF)
    analog_list[3] = bit.band(bit.rshift(elecnt, 8), 0xFF) -- 电芯数量
    analog_list[4] = bit.band(elecnt, 0xFF)
    analog_list[5] = bit.band(bit.rshift(power, 8), 0xFF) -- 电量
    analog_list[6] = bit.band(power, 0xFF)
    analog_list[7] = bit.band(bit.rshift(actual_cap, 8), 0xFF) -- 剩余容量
    analog_list[8] = bit.band(actual_cap, 0xFF)
    analog_list[9] = 0x00 -- SOH
    analog_list[10] = 0x64
    analog_list[11] = 0x00 -- 电流
    analog_list[12] = 0x00 
    analog_list[13] = bit.band(bit.rshift(temp, 8), 0xFF) -- 环境温度
    analog_list[14] = bit.band(temp, 0xFF)
    analog_list[15] = bit.band(bit.rshift(temp, 8), 0xFF) -- 电芯最低温度
    analog_list[16] = bit.band(temp, 0xFF)
    analog_list[17] = bit.band(bit.rshift(temp, 8), 0xFF) -- 板卡温度
    analog_list[18] = bit.band(temp, 0xFF)
    for j = 1, len*2 do data[j] = analog_list[adr*2+j] end
    elseif adr==0x3E8 and len == 0x0D and cmd ==3 then  
    local BtCode = "BT206006015730QLSD73932863"
    for i = 1, #BtCode do
        analog_list[i] = string.byte(BtCode,i)
        table.insert(data, analog_list[i])
    end
    end
    local buf = {}
    if len < 1 then return end
    buf[1] = 0x01
    buf[2] = cmd
    buf[3] = len*2
    for i = 1, len*2 do buf[3 + i] = data[i] end
    local crc = crypto.crc16("MODBUS", string.char(unpack(buf)))
    buf[4 + len*2] = bit.band(crc, 0xFF)
    buf[5 + len*2] = bit.band(bit.rshift(crc, 8), 0xFF)
    serial_rs485:send(buf)
end

 function Charger_Data_Send(volt,curr,adr)

    local buf={0,4,6}
    buf[1]=adr
    buf[4]=bit.rshift(volt*10,8)
    buf[5]=bit.band(volt*10,0xFF)
    buf[6]=bit.rshift(curr*100,8)
    buf[7]=bit.band(curr*100,0xFF)
    buf[8]=0
    buf[9]=0
    local crc_buf=string.char(unpack(buf))    
    local crc16 = crypto.crc16("MODBUS",string.sub(crc_buf,1,-1))
    buf[10]=crc16%256
    buf[11]=bit.band(crc16,0xFF00)/256
    --print("充电器状态查询报文",string.char(unpack(buf)):toHex())
    serial_rs485:send(buf)
    
 end

 function Charger_Open_Decvice(adr,sta,volt,curr)--adr 地址码1-12
    
    local buf={adr,15,0,0,0,3,0}                 --sta 充电器状态 FF-开机 00-关机
    buf[8] =sta 
    buf[9] =bit.rshift(volt*100,8)
    buf[10]=bit.band(volt*100,0xFF)
    buf[11]=bit.rshift(curr*100,8)
    buf[12]=bit.band(curr*100,0xFF)
    local crc_buf=string.char(unpack(buf))    
    local crc16 = crypto.crc16("MODBUS",string.sub(crc_buf,1,-1))
    buf[13]=crc16%256
    buf[14]=bit.band(crc16,0xFF00)/256
    serial_rs485:send(buf)
    print("充电器指令",string.char(unpack(buf)):toHex())
end

sys.subscribe("SeekAnalog",function()
    if lcd.DisplayStart==1 then
    if lcd.KeyStatus==2 then
        Analog_Data_Send(3,4,0)
    elseif lcd.KeyStatus==3 then
        Analog_Data_Send(3,7,0)
    end
    --print("发送模拟量")
    end
end)

sys.subscribe("SeekBtcode",function()
    if lcd.DisplayStart==1 then
    Analog_Data_Send(3,0x0D,0x3E8)
    print("发送bit码")
    end
end)


sys.subscribe("SeekCharger",function()
    if lcd.KeyStatus==2 then
    Charger_Data_Send(48,5.5,0)
    elseif lcd.KeyStatus==3 then
    Charger_Data_Send(48,5.5,can.ChaRCodeaddr)
    end
    print("发送充电器信息")
end)



 local function process()
    while true do
        recv_data_process()
        sys.wait(50)
    end
end

--- BMS协议处理初始化
function init()
    serial_rs485:init()
    sys.taskInit(process)
end






