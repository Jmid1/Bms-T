module(..., package.seeall)

local mcp2515 = {}
-- SPI 指令集
mcp2515.RESET         =     0xC0
mcp2515.READ          =     0x03
mcp2515.WRITE         =     0x02

-- Configuration Registers
mcp2515.CANSTAT         = 0x0E
mcp2515.CANCTRL         = 0x0F
mcp2515.CNF3            = 0x28
mcp2515.CNF2            = 0x29
mcp2515.CNF1            = 0x2A
mcp2515.CANINTE         = 0x2B
mcp2515.CANINTF         = 0x2C

--  Recieve Filters
mcp2515.RXF0SIDH        = 0x00
mcp2515.RXF0SIDL        = 0x01
mcp2515.RXF0EID8        = 0x02
mcp2515.RXF0EID0        = 0x03

-- CNF1
-- CNF2 
mcp2515.PHSEG1_3TQ      = 0x10
mcp2515.PRSEG_1TQ       = 0x00
-- CNF3
mcp2515.PHSEG2_3TQ      = 0x02

-- CANINTE
-- CANINTF
-- CANCTRL 
mcp2515.REQOP_CONFIG    = 0x80--配置模式
mcp2515.REQOP_NORMAL    = 0x00--正常模式
mcp2515.CLKOUT_ENABLED  = 0x04

-- RXBnCTRL
-- TXBnCTRL

-- Receive Masks
mcp2515.RXM0SIDH        = 0x20
mcp2515.RXM0SIDL        = 0x21
mcp2515.RXM0EID8        = 0x22
mcp2515.RXM0EID0        = 0x23
-- Tx Buffer 0
mcp2515.TXB0CTRL        = 0x30
mcp2515.TXB0SIDH        = 0x31
mcp2515.TXB0SIDL        = 0x32
mcp2515.TXB0EID8        = 0x33
mcp2515.TXB0EID0        = 0x34
mcp2515.TXB0DLC         = 0x35
mcp2515.TXB0D0          = 0x36

-- Tx Buffer 1
-- Tx Buffer 2
-- Rx Buffer 0
mcp2515.RXB0CTRL        = 0x60
mcp2515.RXB0SIDH        = 0x61
mcp2515.RXB0SIDL        = 0x62
mcp2515.RXB0EID8        = 0x63
mcp2515.RXB0EID0        = 0x64
mcp2515.RXB0DLC         = 0x65
mcp2515.RXB0D0          = 0x66
-- Rx Buffer 1
mcp2515.RXB1SIDH        = 0x71
mcp2515.RXB1SIDL        = 0x72
mcp2515.RXB1EID8        = 0x73
mcp2515.RXB1EID0        = 0x74
mcp2515.RXB1DLC         = 0x75
mcp2515.RXB1D0          = 0x76


local function write(addr,...)
    mcp2515.cs(0)
    spi.send(mcp2515.sp, string.char(mcp2515.WRITE,addr,...))
    mcp2515.cs(1)
end

local function read(addr,len)
    mcp2515.cs(0)
    spi.send(mcp2515.sp, string.char(mcp2515.READ,addr))
    local val = spi.recv(mcp2515.sp,len or 1)
	mcp2515.cs(1)
    if val then
        return string.byte(val,1,len)
    end
end

--[[ 
mcp2515 复位
@api mcp2515.reset()
@usage
mcp2515.reset()
]]
local function reset()
    mcp2515.cs(0)
    spi.send(mcp2515.sp, string.char(mcp2515.RESET))
    print("[mcp2515]","复位",mcp2515.sp)
	mcp2515.cs(1)
end

--[[ 
mcp2515 数据发送
@api mcp2515.send_buffer(config,...)
@table config 接收数据参数 id:报文ID ide:是否为扩展帧 rtr:是否为远程帧
@number ... 发送数据 数据个数不可大于8
@usage
mcp2515.send_buffer({id = 0x7FF,ide = false,rtr = false},0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07)--标准帧,数据帧
mcp2515.send_buffer({id = 0x1FFFFFE6,ide = true,rtr = false},0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07)--扩展帧,数据帧
mcp2515.send_buffer({id = 0x7FF,ide = false,rtr = true},0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07)--标准帧,远程帧
mcp2515.send_buffer({id = 0x1FFFFFE6,ide = true,rtr = true},0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07)--扩展帧,远程帧
]]
function send_buffer(config,...)

    if config.ide then
        write(mcp2515.TXB0SIDH,bit.band(bit.rshift(config.id,21),0xFF))-- 发送缓冲器0标准标识符高位
        write(mcp2515.TXB0SIDL,bit.bor(bit.band(bit.rshift(config.id,16),0x03),0x08,bit.band(bit.rshift(config.id,13),0xE0)))-- 发送缓冲器0标准标识符低位与缓冲器0标拓展识符最高两位(第3位为发送拓展标识符使能位)
        write(mcp2515.TXB0EID8,bit.band(bit.rshift(config.id,8),0xFF))-- 发送缓冲器0标拓展识符高位
        write(mcp2515.TXB0EID0,bit.band(config.id,0xFF))-- 发送缓冲器0标拓展识符低位
    else
        write(mcp2515.TXB0SIDH,bit.band(bit.rshift(config.id,3),0xFF))-- 发送缓冲器0标准标识符高位
        write(mcp2515.TXB0SIDL,bit.lshift(bit.band(config.id,0x07),5))-- 发送缓冲器0标准标识符低位
    end
    if select("#",...)>8 then
        log.error("mcp2515","send_buffer")
        return
    end
    local delay = 0
    while bit.band(read(mcp2515.TXB0CTRL),0x08) ~=0 and delay<5 do
        sys.wait(10)
        delay = delay+1
    end
    write(mcp2515.TXB0D0,...)--将待发送的数据写入发送缓冲寄存器
    if config.rtr then
        write(mcp2515.TXB0DLC,bit.bor(select("#",...),0x40))--将本帧待发送的数据长度写入发送缓冲器0的发送长度寄存器
    else
        write(mcp2515.TXB0DLC,select("#",...))--将本帧待发送的数据长度写入发送缓冲器0的发送长度寄存器
    end
    write(mcp2515.TXB0CTRL,0x08)--请求发送报文
    print("[mcp2515]","CAN发送的数据",string.format('%x',config.id),string.char(...):toHex())
end

--[[ 
mcp2515 数据接收
@api mcp2515.receive_buffer()
@return number len 接收数据长度
@return string buff 接收数据
@return table config 接收数据参数 id:报文ID ide:是否为扩展帧 rtr:是否为远程帧
@usage
sys.subscribe("mcp2515", function(len,buff,config)
    print("mcp2515", len,buff:byte(1,len))
    for k, v in pairs(config) do
        print(k,v)
    end
end)
]]
local function receive_buffer()
    local config = {}
    local len
    local buff
    local temp = read(mcp2515.CANINTF)
    --print("CANINTF的值为",temp)
    if bit.band(temp ,0x01) ~= 0  then
        local sidh=read(mcp2515.RXB0SIDH)
        local sidl=read(mcp2515.RXB0SIDL)
        if bit.band(sidl,0x08) ==0 then
            config.ide = false
            config.id = bit.bor(bit.lshift(sidh,3),bit.rshift(sidl,5))
            if bit.band(sidl,0x10) ==0 then
                config.rtr = false
            else
                config.rtr = true
            end
        else
            config.ide = true
            local eidh=read(mcp2515.RXB0EID8)
            local eidl=read(mcp2515.RXB0EID0)
            config.id = bit.bor(bit.lshift(sidh,21),bit.lshift(bit.band(sidl,0xE0),13),bit.lshift(bit.band(sidl,0x03),16),bit.lshift(eidh,8),eidl)
        end
        local dlc=read(mcp2515.RXB0DLC)
        if config.ide then
            if bit.band(dlc,0x40) == 0 then
                config.rtr = false
            else
                config.rtr = true
            end
        end
        len = bit.band(dlc,0x0F)
        buff = string.char(read(mcp2515.RXB0D0,len))
        if len then
            sys.publish("mcp2515", len,buff,config)
        end
    end

    if bit.band(temp ,0x02) ~= 0  then
        local config_1 = {}
        local len_1
        local buff_1
        local sidh=read(mcp2515.RXB1SIDH)
        local sidl=read(mcp2515.RXB1SIDL)
        if bit.band(sidl,0x08) ==0 then
            config_1.ide = false
            config_1.id = bit.bor(bit.lshift(sidh,3),bit.rshift(sidl,5))
            if bit.band(sidl,0x10) ==0 then
                config_1.rtr = false
            else
                config_1.rtr = true
            end
        else
            config_1.ide = true
            local eidh=read(mcp2515.RXB1EID8)
            local eidl=read(mcp2515.RXB1EID0)
            config_1.id = bit.bor(bit.lshift(sidh,21),bit.lshift(bit.band(sidl,0xE0),13),bit.lshift(bit.band(sidl,0x03),16),bit.lshift(eidh,8),eidl)
        end
        local dlc=read(mcp2515.RXB1DLC)
        if config_1.ide then
            if bit.band(dlc,0x40) == 0 then
                config_1.rtr = false
            else
                config_1.rtr = true
            end
        end
        len_1 = bit.band(dlc,0x0F)
        buff_1 = string.char(read(mcp2515.RXB1D0,len_1))
        if len_1 then
            sys.publish("mcp2515", len_1,buff_1,config_1)
        end
    end

    write(mcp2515.CANINTF,0)
    return len,buff,config
end

sys.taskInit(function()
    while true do
        sys.waitUntil("rece2515")
        receive_buffer()
    end
end)

local function mcp2515_int(val)
    --print("[mcp2515]","产生中断",val)
    if val==2 then
        sys.publish("rece2515")
    end
end

--[[
mcp2515 设置模式
@api mcp2515.mode(mode)
@number mode     模式
@usage
mcp2515.mode(mcp2515.REQOP_NORMAL)--进入正常模式
]]
local function mode(mod)
    write(mcp2515.CANCTRL,bit.bor(mod,mcp2515.CLKOUT_ENABLED))
	local temp = read(mcp2515.CANSTAT)
    if mod ~= bit.band(temp,0xE0) then
        write(mcp2515.CANCTRL,bit.bor(mod,mcp2515.CLKOUT_ENABLED))
    end
end

--[[
mcp2515 设置波特率(注意:需在配置模式使用)
@api mcp2515.baud(baud)
@number baud     波特率
@usage
mcp2515.baud(mcp2515.CAN_500Kbps)
]]
local function baud(bau)
    write(mcp2515.CNF1,bau)
end

--[[
mcp2515 设置过滤表(注意:需在配置模式使用)
@api mcp2515.filter(id,ide,shield)
@number id     id
@bool ide     是否为扩展帧
@bool shield     是否为屏蔽表
@usage
mcp2515.filter(0x1FF,false,false)
]]
function filter(id,ide,shield)
    mode(mcp2515.REQOP_CONFIG)--进入配置模式
    if ide then
        if shield then
            write(mcp2515.RXM0SIDH,bit.band(bit.rshift(id,21),0xFF))--配置验收屏蔽寄存器n标准标识符高位
	        write(mcp2515.RXM0SIDL,bit.bor(bit.band(bit.rshift(id,16),0x03),bit.band(bit.rshift(id,13),0xE0)))--配置验收屏蔽寄存器n标准标识符低位
            write(mcp2515.RXM0EID8,bit.band(bit.rshift(id,8),0xFF))--配置验收屏蔽寄存器n拓展标识符高位
	        write(mcp2515.RXM0EID0,bit.band(id,0xFF))--配置验收屏蔽寄存器n拓展标识符低位
        else
            write(mcp2515.RXF0SIDH,bit.band(bit.rshift(id,21),0xFF))--配置验收滤波寄存器n标准标识符高位
            write(mcp2515.RXF0SIDL,bit.bor(bit.band(bit.rshift(id,16),0x03),0x08,bit.band(bit.rshift(id,13),0xE0)))--配置验收滤波寄存器n标准标识符低位(第3位为接收拓展标识符使能位)
            write(mcp2515.RXF0EID8,bit.band(bit.rshift(id,8),0xFF))--配置验收滤波寄存器n标准标识符高位
	        write(mcp2515.RXF0EID0,bit.band(id,0xFF))--配置验收滤波寄存器n标准标识符低位
        end
    else
        if shield then
            write(mcp2515.RXM0SIDH,bit.band(bit.rshift(id,3),0xFF))--配置验收屏蔽寄存器n标准标识符高位
	        write(mcp2515.RXM0SIDL,bit.lshift(bit.band(id,0x07),5))--配置验收屏蔽寄存器n标准标识符低位
        else
            write(mcp2515.RXF0SIDH,bit.band(bit.rshift(id,3),0xFF))--配置验收滤波寄存器n标准标识符高位
	        write(mcp2515.RXF0SIDL,bit.lshift(bit.band(id,0x07),5))--配置验收滤波寄存器n标准标识符低位(第3位为接收拓展标识符使能位)
        end
    end
    mode(mcp2515.REQOP_NORMAL)--进入正常模式
end

--[[
mcp2515 初始化
@api mcp2515.init(spi_id,cs,int,baud)
@number spi_id spi端口号
@number cs      cs引脚
@number int     int引脚
@number baud     波特率
@return bool 初始化结果
@usage
spi_mcp2515 = spi.setup(mcp2515_spi,nil,0,0,8,20*1000*1000,spi.MSB,1,0)
mcp2515.init(mcp2515_spi,mcp2515_cs,mcp2515_int,mcp2515.CAN_500Kbps)
]]
function init(spi_id,cs,int,bau)
    mcp2515.sp = spi_id
    mcp2515.cs = pins.setup(cs, 0, pio.PULLUP)
    mcp2515.cs(1)
    pins.setup(int,mcp2515_int, pio.PULLUP)
    reset()
    -- 以下部分根据需求参考手册修改
    -- 配置CNF1,CNF2,CNF3,
    baud(bau)
	write(mcp2515.CNF2,bit.bor(0x80,mcp2515.PHSEG1_3TQ,mcp2515.PRSEG_1TQ))
	write(mcp2515.CNF3,mcp2515.PHSEG2_3TQ)
	write(mcp2515.RXB0SIDH,0x00)--清空接收缓冲器0的标准标识符高位
	write(mcp2515.RXB0SIDL,0x00)--清空接收缓冲器0的标准标识符低位
    write(mcp2515.RXB0EID8,0x00)--清空接收缓冲器0的拓展标识符高位
	write(mcp2515.RXB0EID0,0x00)--清空接收缓冲器0的拓展标识符低位
	write(mcp2515.CANINTF,0x00)--清空CAN中断标志寄存器的所有位(必须由MCU清空)
	write(mcp2515.CANINTE,0x01)--配置CAN中断使能寄存器的接收缓冲器0满中断使能,其它位禁止中断
    write(mcp2515.RXB0CTRL,0x04)--如果RXB0满了，RXB0接收到的报文将被滚存到RXB1
    mode(mcp2515.REQOP_NORMAL)--进入正常模式
    --mode(mcp2515.OSM_ENABLED)--进入正常单触发模式
    sys.taskInit(function()
        while true do            
            if bit.band(read(mcp2515.CANINTF) ,0x01) == 1 then
                --print("CAN中断信号产生")
                sys.publish("rece2515")    
            end
            sys.wait(10)
        end
    end)
    return true
end


--[[--*
接收缓冲器中断方式为下降沿中断（2） 过程2 - 1



--]]