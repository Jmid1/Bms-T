module(..., package.seeall)
require "hwcfg"
Interface_Type = {}
Interface_Type.TTL = 0
Interface_Type.RS485 = 1

local RECV_BUFF_MAX = 2048

local serials = {}

local mt = {}
mt.__index = mt
local function mt_serial(mode, id, baud,dir_io)
    local o = {
        mode = mode,
        id = id or -1,
        baud = baud or 115200,
        io = dir_io or nil,
        recv_buff = {}
    }
    serials[id] = setmetatable(o, mt)
    return serials[id]
end

--- 实例化串口对象
---@param mode any ttl或者485
---@param id any 串口ID
---@param baud any 波特率
---@param dir_io any opt，485模式时方向控制IO
function new(mode, id, baud, dir_io)
    if (type(mode) ~= "number") or
        ((mode ~= Interface_Type.TTL) and (mode ~= Interface_Type.RS485)) then
        log.error("serial", "mode params error")
        return nil
    end

    if (type(id) ~= "number") or (id < 0) then
        log.error("serial", "id params error")
        return nil
    end

    return mt_serial(mode, id, baud,dir_io)
end

--- 串口接收数据缓存到buff
---@param id any 串口ID
---@param len any 数据长度
local function read(id, len)
    local data = ""
    while true do
        data = uart.read(id, "1")
        if not data or string.len(data) == 0 then break end
        if table.getn(serials[id].recv_buff) > RECV_BUFF_MAX then
            table.remove(serials[id].recv_buff, 1)
        end
        table.insert(serials[id].recv_buff, data)
    end
    --log.info("testUart.read", tostring(table.getn(serials[id].recv_buff)))
end

--- 初始化
function mt:init()
    uart.on(self.id, "receive", read)
    if self.mode == Interface_Type.RS485 then
        uart.setup(self.id, self.baud, 8, uart.PAR_NONE, uart.STOP_1, 0, 1)
        if self.io ~= nil then
            uart.set_rs485_oe(self.id, self.io, 1)
        else
            log.error("serial", "RS485 init but params error")
        end
    else
        uart.setup(self.id, self.baud, 8, uart.PAR_NONE, uart.STOP_1, 0, 0)
    end
end

--- 串口发送
---@param buff any 发送数据
function mt:send(buff)
    if type(buff) == "table" then
        --for i = 1, #buff do uart.write(self.id, buff[i]) end
        local temp = string.char(unpack(buff))
        uart.write(self.id, temp)
        --print("485上传数据(表-串)：",temp:toHex())
    elseif type(buff) == "string" then
        uart.write(self.id, buff)
        print("485上传数据(串)：",buff:toHex())
    else
        uart.write(self.id, buff)
    end
end

--- 获取串口接收数据数量
function mt:get_recv_cnt() return table.getn(self.recv_buff) end

--- 获取串口接收缓存数据
function mt:get_recv()
    buff = self.recv_buff
    self.recv_buff = {}
    return buff
end

--- 获取1字节串口接收数据
function mt:get_recv_byte()
    if #self.recv_buff == 0 then return nil end
    local data = self.recv_buff[1]
    table.remove(self.recv_buff, 1)
    return data
end



-- local serial_rs232 = new(Interface_Type.TTL,hw_cfg.RS232_UART_ID, 9600,nil)
-- serial_rs232 : init()
-- local serial_rs485 = new(Interface_Type.RS485,hw_cfg.RS485_UART_ID,9600,hw_cfg.RS485_DIR)
-- serial_rs485 : init()

-- sys.taskInit(function()
--     while true do            
--         local buff = {1,2,3,4,5,0,0,0}
--         serial_rs232:send(buff)
--         serial_rs485:send(buff)
--         sys.wait(500)
--     end
-- end)