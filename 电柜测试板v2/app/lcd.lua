module(..., package.seeall)
require "items"
require "serial"
require"com_process"
require"can"

OpreateStart=0
DisplayStart=0
DisplayIndex=1
OpreaIndex = 1
KeyStatus=0
OpreaResult="OK"

ProGressAdress=0x1099
InstructSwitch=0
local serial_rs232 = serial.new(serial.Interface_Type.TTL,hw_cfg.RS232_UART_ID,115200,hw_cfg.RS485_DIR)
 function dcbus_frame_send(len,code,adr,data)
    
    local buf = {0xAA, 0x55, 0}
    buf[4] = len                              -- 添加基本字段
    buf[5] = code
    buf[6] = bit.rshift(bit.band(adr, 0xFF00), 8)  -- 高字节
    buf[7] = bit.band(adr, 0xFF)                   -- 低字节  
    if type(data) == "number" then
        buf[8]=0
        buf[9]=data
    else
        --data=data:string.sub(1,-2)
        for i=1,#data do 
            buf[i+7]=string.byte(data,i)
        end
        buf[#data+8] =0
        buf[#data+9] =0
        if (#data)%2 ~= 0 then
            buf[#data+10]=0
        end
        if #data==3 or #data==4 or    
           #data==5 or #data==6 or  
           #data==7 or #data==8 or 
           (#data==9 and string.byte(data,1)~=0xB2)
        then 
            len =len + math.floor((#data-1)/2)*2
            print("len长度",len)
            buf[4] = len
        end
    end 
    local crc_buf=string.char(unpack(buf))    
    local crc16 = crypto.crc16("MODBUS",string.sub(crc_buf,3,-1))
    buf[len+3]=bit.band(crc16, 0xFF)  --crc16%256
    buf[len+4]=bit.rshift(bit.band(crc16, 0xFF00), 8)
    serial_rs232:send(buf)
    --print("232发送的数据",string.char(unpack(buf)):toHex())
end


--     local buf = {}
--     buf[1]=0xAA
--     buf[2]=0X55
--     buf[3]=0
--     buf[4]=len
--     buf[5]=code
--     buf[6]=bit.band(adr,0xFF00)/256
--     buf[7]=adr%256   
--     if len==9 then
--     buf[8]=string.byte(data,1)
--     buf[9]=string.byte(data,2)
--     buf[10]=0
--     buf[11]=0 
    
--     elseif len ==17 then
--     local txt={0xB2,0xE2,0xCA,0xD4,0xD6,0xD0,0x2E,0x2E,0x2E,0,0,0}
--     for i=1, #txt do
--     buf[i+7]=txt[i]
--     end
--     elseif len == 0x17 then
--     for i=1,15 do 
--     buf[i+7]=string.byte(data,i)
--     end 
--     buf[23]=0
--     buf[24]=0
--     buf[25]=0
--     else 
--     buf[8]=0
--     buf[9]=data
--     end
--     local crc_buf=string.char(unpack(buf))    
--     local crc16 = crypto.crc16("MODBUS",string.sub(crc_buf,3,-1))
--     buf[len+3]=crc16%256
--     buf[len+4]=bit.band(crc16,0xFF00)/256
--     serial_rs232:send(buf)
--    print("232发送的数据",string.char(unpack(buf)):toHex())
-- end



function key_status_check()

    if  KeyStatus==1   then
        OpreaIndex=1 
        DisplayIndex=1
    elseif KeyStatus==2 or KeyStatus==3 then
        OpreaIndex=14 
        DisplayIndex=14 
    elseif KeyStatus==4 then
        OpreaIndex=22 
        DisplayIndex=22
    elseif KeyStatus==5 then
        OpreaIndex=23 
        DisplayIndex=23
    end

end

local function dcbus_frame_analyse()
    local byte = {}
    -- print("dcbus_frame recv in")
    local buf = serial_rs232:get_recv()
    for i = 1, #buf do
        if not buf[i] then return end
        byte[i] = string.byte(buf[i])
    end
    -- print("232数据")
    if byte[1]==0xAA and byte[2]==0x55 and byte[3]==0 then
        if  (#byte-4) == byte[4] then
          if byte[5]==0xF1 or byte[5]==0xF2 then
            local StrBuf = table.concat(buf)
            local crc = crypto.crc16("MODBUS",string.sub(StrBuf,3,-3))
            local crc16 = string.byte(StrBuf,-2)+ string.byte(StrBuf,-1)*256
            if  crc == crc16 then
                items.items_tab[DisplayIndex].ack=items.items_tab[DisplayIndex].ack+1
                if DisplayIndex==7 then
                if items.items_tab[DisplayIndex].ack==com_process.Bat_Rs485_Tab.Num+2 then
                      print("电压列表更新完成",DisplayIndex,items.items_tab[DisplayIndex].ack)
                    items.items_tab[DisplayIndex].ack=2
                    items.VoltlistFlag=2
                  
                end
                end 
                --print("CRC数据帧接收正常")
                if byte[4]==8 then
                    local adr= byte[6]*256+byte[7]
                    if adr==0x1000 then
                        if  byte[10]==1 then
                            print("开始测试")
                        elseif  byte[10]==0 then
                            OpreateStart=0
                            DisplayStart=0
                            print("测试结束")
                        end
                    
                    elseif adr==0x10A7 then
                    if byte[10]==1 then
                        com_process.Bat_Rs485_Tab.Bee="OK"
                    else
                        com_process.Bat_Rs485_Tab.Bee="NG"
                    end
                    print("接收到蜂鸣器确认结果",com_process.Bat_Rs485_Tab.Bee,"当前应答次数",items.items_tab[DisplayIndex].ack)
                    items.items_tab[DisplayIndex].ack=1
                    items.OnceBeeRecvCommand=1
                    com_process.modbus_frame_send(5,0x401,2)

                    elseif adr==0x10AA then
                    local TcpDataSendSignal= byte[10]
                    print("测试结束,发送测试结果")

                    elseif adr==0x10B0 then
                        print("接收仓门检查确认")
                        if byte[10]==1 then
                        can.War_Can_Tab.OpenDoor="OK"
                        else
                        can.War_Can_Tab.OpenDoor="NG"
                        end
                        items.items_tab[DisplayIndex].ack=1
                        items.OnceDorRecvCommand=1

                    elseif adr==0x10B6 then
                        
                        if byte[10]==1 then
                        can.War_Can_Tab.Lock="OK"
                        else
                        can.War_Can_Tab.Lock="NG"
                        end
                        items.items_tab[DisplayIndex].ack=1
                        items.OnceChaRecvCommand=1
                        print("接收锁状态",can.War_Can_Tab.Charge_CAN,items.OnceChaRecvCommand)
              
                end

                elseif byte[4]==0x10 and byte[6]==0x10 and byte[7]==0x01 then
                    local adr= byte[6]*256+byte[7]
                    local len= byte[8]
                    if adr==0x1001 and len==5 then
                       KeyStatus=byte[10]+byte[12]*2+byte[14]*3+byte[16]*4+byte[18]*5
                       OpreateStart = 1
                       DisplayStart = 1
                       print("测试内容",KeyStatus)
                       items.ClearAllOperaSignal()
                       key_status_check()
                       
                    end
              
                end
       
            end
          else print("funccode faullt")
          end
        else print("length faullt")
        end
   else 
   end
end



local function Process_Rs232()
    while true do
        dcbus_frame_analyse()
        sys.wait(10)
    end
end

--- BMS协议处理初始化
function init()
    serial_rs232:init()
    sys.taskInit(Process_Rs232)
end