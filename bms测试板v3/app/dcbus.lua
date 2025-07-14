

module(..., package.seeall)
require "serial"
require "hwcfg"
require "modbus"
require "items"
local serial_rs232 = serial.new(serial.Interface_Type.TTL,hwcfg.RS232_UART_ID,115200,hwcfg.RS485_DIR)

ProGressAdress=0x1041
DisplayIndex=1
OpreaStart=0
DisplayStart=0
TcpDataSendSignal=1
OperaTimeTotal=0


 function dcbus_frame_send(len,code,adr,data)
    local buf = {}
    buf[1]=0xAA
    buf[2]=0X55
    buf[3]=0
    buf[4]=len
    buf[5]=code
    buf[6]=bit.band(adr,0xFF00)/256
    buf[7]=adr%256   
    if len==9 then
    buf[8]=string.byte(data,1)
    buf[9]=string.byte(data,2)
    buf[10]=0
    buf[11]=0  
    elseif len ==17 then
    local txt={0xB2,0xE2,0xCA,0xD4,0xD6,0xD0,0x2E,0x2E,0x2E,0,0,0}
    for i=1, #txt do
    buf[i+7]=txt[i]
    end
    elseif len == 0x17 then
    for i=1,15 do 
    buf[i+7]=string.byte(data,i)
    end 
    buf[23]=0
    buf[24]=0
    buf[25]=0
    elseif len == 0x14 then
    for i=1,12 do 
    buf[i+7]=string.byte(data,i)
    end 
    buf[20]=0
    buf[21]=0
    buf[22]=0
    else
    buf[8]=0
    buf[9]=data
    end
    local crc_buf=string.char(unpack(buf))    
    local crc16 = crypto.crc16("MODBUS",string.sub(crc_buf,3,-1))
    buf[len+3]=crc16%256
    buf[len+4]=bit.band(crc16,0xFF00)/256
    serial_rs232:send(buf)
    print("232发送的数据",string.char(unpack(buf)):toHex())
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
                --print("CRC数据帧接收正常")
                if byte[4]==8 then
                    local adr= byte[6]*256+byte[7]
                    if adr==0x1000 then
                        if byte[10]==1 then
                         OpreaStart   = 1
                         DisplayStart = 1
                         print("开始测试",items.items_tab[DisplayIndex].ack)
                         items.items_tab[DisplayIndex].ack=0
                         OperaTimeTotal=rtos.tick()
                        elseif  byte[10]==0 then
                         items.ClearAllOperaSignal()
                         print("测试结束")
                        end
                    elseif adr==0x104E then
                        if byte[10]==1 then
                            modbus.torigin.bee="OK"
                           
                        else
                            modbus.torigin.bee="NG"
                        end
                        print("接收到蜂鸣器确认结果", modbus.torigin.bee,"当前应答次数",items.items_tab[DisplayIndex].ack)
                        items.items_tab[DisplayIndex].ack=1
                        items.OnceBeeRecvCommand=1
                        modbus.modbus_frame_send(5,0x401,2)
                    elseif adr==0x104F then
                        TcpDataSendSignal= byte[10]
                    elseif adr==0x1058 then
                        items.MicroSensorRecvFlag=byte[10]
                        print("拆卸报警接收确认","当前应答次数", items.items_tab[DisplayIndex].ack)
                        items.items_tab[DisplayIndex].ack=1
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


