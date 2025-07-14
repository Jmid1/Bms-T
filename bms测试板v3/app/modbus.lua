module(..., package.seeall)
require "serial"
require "hwcfg"
require "items"
require "operate"
local serial_rs485 = serial.new(serial.Interface_Type.RS485,hwcfg.RS485_UART_ID,9600,hwcfg.RS485_DIR)

torigin =
{
   id="NG",
   mesId="NG",
   number="NG",
   time="NG",
   object_id="NG",
   cells="NG",
   result="NG",
   mostemp="NG",
   battemp="NG",
   mosfet="NG",
   ovp1="NG",
   ovp1_rec="NG",
   ovp2="NG",
   ovp2_rec="NG",
   uvp1="NG",
   uvp1_rec="NG",
   uvp2="NG",
   uvp2_rec="NG",
   cur_clib="NG",
   balance="OK",
   online="NG",
   bee="NG",
   rs485="NG",
   VoltDis="NG"

}
local volt_table={}
local min=0
local max=0
local imin=0
local imax=0
-- local function bubbleSort(arr)
--     local n = #arr
--     local min,max
--     -- 外层循环控制排序轮数
--     for i = 1, n - 1 do
--         -- 内层循环比较相邻元素
--         for j = 1, n - i do
--             -- 如果前一个元素比后一个大，则交换它们
--             if arr[j] > arr[j + 1] then
--                 arr[j], arr[j + 1] = arr[j + 1], arr[j]
--             end
--         end
--     end
--     min=arr[1]
--     max=arr[#arr]
--     return min,max
-- end
local function bubbleSort(arr)

    local n = #arr
    local min=9999
    local max=0
    local imin=0
    local imax=0

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
    return result
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
    print("485数据发送",string.char(unpack(buf)):toHex())
 end

 local function recv_data_process()
  
    local byte = {}
    local buff = serial_rs485:get_recv()
    for i = 1, #buff do
        if not buff[i] then return end
        byte[i] = string.byte(buff[i])
    end
    -- print("端口接收数据Buff")
    if  byte[1]==1 then
       if byte[2]==1 or byte[2]==3 or byte[2]==5 then
        local crc_buf = table.concat(buff)
        local crc16 = crypto.crc16("MODBUS",crc_buf:sub(1,-3))
        local crc_new = byte[#byte-1]+ byte[#byte]*256
        if crc16==crc_new then
            torigin.rs485 = "OK"
            --print("CRC16 Check Right")
            local len = byte[3]
            if (#byte-5)==len  then
             
             if  byte[2]==3 then
                if items.items_tab[operate.OpreaIndex].name=="Rs485" then
                    local result = ""
                    local character
                    for i=4,#buff-2 do
                    result = result .. string.format("%02X", byte[i])
                    end
                    for i=1,13 do
                       character=string.byte(result,i)
                       if character>=0x3A then
                          items.Bluetooth=1
                       end
                    end
                    if items.Bluetooth==1 then
                        torigin.object_id = result:sub(1,12)
                    else
                        torigin.object_id = result:gsub("^0", "")
                    end
                    print("IMEI编码",torigin.object_id,"蓝牙BMS信号",items.Bluetooth)
                elseif items.items_tab[operate.OpreaIndex].name=="Cells" then
                    torigin.cells =  byte[4]*256+byte[5]
                    
                    print("电芯串数",torigin.cells)
                elseif items.items_tab[operate.OpreaIndex].name=="VoltDis" then
                    local mostemp =byte[6]*256+byte[7]
                    local battemp_min = byte[4]*256+byte[5]
                    local battemp_max =  byte[48]*256+byte[49]
                    print ("mos温度,电池min温度,电池max温度",mostemp,battemp_min,battemp_max)
                    if mostemp>0 and mostemp<100 then  
                        torigin.mostemp="OK"
                    else 
                        torigin.mostemp="NG"
                    end
                    if battemp_min>0 and battemp_min<100 and 
                       battemp_max >0 and battemp_max<100 then 
                        torigin.battemp="OK"
                    else 
                        torigin.battemp="NG"
                    end
                    --print ("mos温度,电池温度",torigin.mostemp,torigin.battemp)
                    volt_table = {}
                    for i=1,torigin.cells do
                        local LowBit  = i*2+6
                        local HighBit = i*2+7
                        if i>20 then 
                            LowBit=LowBit+2 
                            HighBit=HighBit+2
                        end
                        volt_table[i] = byte[LowBit]*256+byte[HighBit] 
                        print("单窜电压",volt_table[i] )
                    end
            
                        min,max,imin,imax = bubbleSort(volt_table)
                        print("单节最小电压",imin,min,"单节最大电压",imax,max)
                        if max< 4000 and min> 2500 then
                                if max - min <50 then
                                    torigin.VoltDis="OK"
                                else
                                    torigin.VoltDis="NG"
                                end
                        else
                                    torigin.VoltDis="NG"
                                    --print("单串电压异常")
                        end
                    

                elseif items.items_tab[operate.OpreaIndex].name=="Online" then
                    local net_signal =  byte[5]
                    if  net_signal>0 then
                        torigin.online="OK"
                    else
                        torigin.online="NG"
                    end
                    print("网络信号值",net_signal)
                    
                elseif  items.items_tab[operate.OpreaIndex].name=="CurrZero" then
                    local zero_curr  =  byte[4]
                    if 1==bit.band(zero_curr,1) then
                        items.ZeroCurrClib="OK"
                    else
                        items.ZeroCurrClib="NG"
                    end
                    print("零电流",items.ZeroCurrClib)
                elseif items.items_tab[operate.OpreaIndex].name=="CurrCalib3" or items.items_tab[operate.OpreaIndex].name=="CurrCalib1"then
                    local clib = bit.band(bit.rshift(byte[6],3),0x01)
                    if clib==0 then 
                        torigin.cur_clib ="OK"
                    else
                        torigin.cur_clib ="NG"
                    end
                    print("电流校准值",clib)
                elseif items.items_tab[operate.OpreaIndex].name=="UnderVolt1" then
                    local uvp1 = bit.band(bit.rshift(byte[5],3),0x01)
                    if uvp1 == 1 then
                    torigin.uvp1= "OK"
                    else  torigin.uvp1="NG"
                    end
                    print("单体欠压1",torigin.uvp1,uvp1)
                
                elseif items.items_tab[operate.OpreaIndex].name=="UnderVoltRec1" then
                    local uvp1_rec = bit.band(bit.rshift(byte[5],3),0x01)
                    if uvp1_rec == 0 then
                    torigin.uvp1_rec= "OK"
                    else  torigin.uvp1_rec="NG"
                    end
                    print("单体欠压恢复1",torigin.uvp1_rec,uvp1_rec)
                elseif items.items_tab[operate.OpreaIndex].name=="UnderVolt2" then
                    local uvp2 = bit.band(bit.rshift(byte[5],3),0x01)
                    if uvp2 == 1 then
                    torigin.uvp2= "OK"
                    else  torigin.uvp2="NG"
                    end
                    print("单体欠压2",torigin.uvp2,uvp2)
                elseif items.items_tab[operate.OpreaIndex].name=="UnderVoltRec2" then
                    local uvp2_rec = bit.band(bit.rshift(byte[5],3),0x01)
                    if uvp2_rec == 0 then
                    torigin.uvp2_rec= "OK"
                    else  torigin.uvp2_rec="NG"
                    end
                    print("单体欠压恢复2",torigin.uvp2_rec,uvp2_rec)
                -- elseif items.items_tab[operate.OpreaIndex].name=="VoltAverage" then 
                --     local balance=bit.band(bit.rshift(byte[6],5),0x01)
                --     print("拆卸警报值",balance)
                --     if balance==0 and items.MicroSensorRecvFlag==1 then
                --        torigin.balance="OK"
                --     else
                --        torigin.balance="NG"
                --     end
                elseif items.items_tab[operate.OpreaIndex].name=="OverVolt1" then
                    local ovp1 = bit.band(bit.rshift(byte[5],2),0x01)
                    if ovp1 == 1 then
                    torigin.ovp1= "OK"
                    else  torigin.ovp1="NG"
                    end
                    print("单体过压1",torigin.ovp1,ovp1)
                elseif items.items_tab[operate.OpreaIndex].name=="OverVoltRec1" then
                    local ovp1_rec = bit.band(bit.rshift(byte[5],2),0x01)
                    if ovp1_rec == 0 then
                    torigin.ovp1_rec= "OK"
                    else  torigin.ovp1_rec="NG"
                    end
                    print("单体过压恢复1",torigin.ovp1_rec,ovp1_rec)
                elseif items.items_tab[operate.OpreaIndex].name=="OverVolt2" then
                    local ovp2 = bit.band(bit.rshift(byte[5],2),0x01)
                    if ovp2 == 1 then
                    torigin.ovp2= "OK"
                    else  torigin.ovp2="NG"
                    end
                    print("单体过压2",torigin.ovp2,ovp2)
                elseif items.items_tab[operate.OpreaIndex].name=="OverVoltRec2" then
                    local ovp2_rec = bit.band(bit.rshift(byte[5],2),0x01)
                    if ovp2_rec == 0 then
                    torigin.ovp2_rec= "OK"
                    else  torigin.ovp2_rec="NG"
                    end
                    print("单体过压恢复2",torigin.ovp2_rec,ovp2_rec)
                end
             end

            else
                

            end

        end

       end

    end
   
end


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