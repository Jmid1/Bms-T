module(..., package.seeall)
--
--
----------------------------------------------------------------
--- 16进制字符串转table
---@param str string   16进制字符串
---@param offset number 偏移
---@param len number    截取长度
function hex_str2table(str, offset, len)
    local buff = {}
    for i = 1, #str, 2 do
        local high = tonumber(str:sub(i, i), 16)
        local low = tonumber(str:sub(i + 1, i + 1), 16)
        table.insert(buff, bit.bor(bit.lshift(high, 4), low))
    end
    return buff
end
--
--
----------------------------------------------------------------
--
--- 获取tick
function tick()
    local cur_tick = rtos.tick() * 5
    return cur_tick
end
--
--
----------------------------------------------------------------
--- 获取持续时间
---@param st_tick number 开始时间戳
function dur_tick(st_tick)
    local cur_tick = rtos.tick() * 5
    if cur_tick >= st_tick then return cur_tick - st_tick end
    return  0x5d638865*10 + cur_tick - st_tick + 1
end
-------------------------------------------------------------------

-- 参数:待分割的字符串,分割字符
-- 返回:子串表.(含有空串)
function string_split(str, split_char)
    local sub_str_tab = {}
    while true do
        local pos = string.find(str, split_char,1,true)
       if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1)
        sub_str_tab[#sub_str_tab + 1] = sub_str
        str = string.sub(str, pos + 1, #str)
    end
    return sub_str_tab
end
--[[----------------------------------------------------------------
--数字转二进制
local function ToSecond(num)
	local str = ""
	local tmp = num
	while (tmp > 0) do
		if (tmp % 2 == 1) then
			str = str .. "1"
		else
			str = str .. "0"
		end
		
		tmp = math.modf(tmp / 2)
	end
	str = string.reverse(str)
	if string.len(str) < 16 then
		for i = 1,16-string.len(str) do
			str = "0" .. str
		end
	end
	return str

end
---按位取反
function Negate(num)
	local str = ToSecond(num)
	local len = string.len(str)
	--local rtmp = ""
	--print("字符串为",str)
	local data = 0
	for i = 1, len do
		local st = tonumber(string.sub(str, i, i))
		if (st == 1) then
			--rtmp = rtmp .. "0"
			
		elseif (st == 0) then
			--rtmp = rtmp .. "1"
			data = data + math.pow(2,len-i)
		end
	end
	--rtmp = tostring(rtmp)
	return data
end
--]]
------------------------------------------------------------------

--[[
函数名：diffofloc
功能 ：计算两对经纬度之间的直线距离（近似值）
参数:
  latti1：纬度1（度格式，例如"31.12345"度）
 longti1：经度1（度格式）
 latti2：纬度2（度格式）
 longti2：经度2（度格式）
 typ：距离类型
返回值：typ如果为true，返回的是直线距离(单位米)的平方和；否则返回的是直线距离(单位米)
]]
--[[
function diffofloc(latti1, longti1, latti2, longti2,typ) --typ=true:返回a+b ; 否则是平方和

    local I1,I2,R1,R2,diff,d
    I1,R1=string.match(latti1,"(%d+)%.(%d+)")
    I2,R2=string.match(latti2,"(%d+)%.(%d+)")
    if not I1 or not I2 or not R1 or not R2 then
        return 0
    end

    R1 = I1 .. string.sub(R1,1,5)
    R2 = I2 .. string.sub(R2,1,5)
    d = tonumber(R1)-tonumber(R2)
    d = (d*111-(d*111%100))/100

    if typ == true then
        diff =  (d>0 and d or (-d))
    else
        diff = d * d
    end
        
    I1,R1=string.match(longti1,"(%d+)%.(%d+)")
    I2,R2=string.match(longti2,"(%d+)%.(%d+)")

    if not I1 or not I2 or not R1 or not R2 then
        return 0
    end

    R1 = I1 .. string.sub(R1,1,5)
    R2 = I2 .. string.sub(R2,1,5)
    d = tonumber(R1)-tonumber(R2)

    if typ == true then
        diff =  diff + (d>0 and d or (-d))
    else
        diff =  diff + d*d
    end
    --diff =  diff + d*d

    print("all diff:", diff)
    return diff
end
--]]
--[[
--*CRC8-校验码*(多项式=X8+X2+X+1(0x07),CRC8初8初始值固定为0为0x00)
local CRC8Table =
{
    0x00, 0x07, 0x0E, 0x09, 0x1C, 0x1B, 0x12, 0x15, 0x38, 0x3F, 0x36, 0x31, 0x24, 0x23, 0x2A, 0x2D,
    0x70, 0x77, 0x7E, 0x79, 0x6C, 0x6B, 0x62, 0x65, 0x48, 0x4F, 0x46, 0x41, 0x54, 0x53, 0x5A, 0x5D,
    0xE0, 0xE7, 0xEE, 0xE9, 0xFC, 0xFB, 0xF2, 0xF5, 0xD8, 0xDF, 0xD6, 0xD1, 0xC4, 0xC3, 0xCA, 0xCD,
    0x90, 0x97, 0x9E, 0x99, 0x8C, 0x8B, 0x82, 0x85, 0xA8, 0xAF, 0xA6, 0xA1, 0xB4, 0xB3, 0xBA, 0xBD,
    0xC7, 0xC0, 0xC9, 0xCE, 0xDB, 0xDC, 0xD5, 0xD2, 0xFF, 0xF8, 0xF1, 0xF6, 0xE3, 0xE4, 0xED, 0xEA,
    0xB7, 0xB0, 0xB9, 0xBE, 0xAB, 0xAC, 0xA5, 0xA2, 0x8F, 0x88, 0x81, 0x86, 0x93, 0x94, 0x9D, 0x9A,
    0x27, 0x20, 0x29, 0x2E, 0x3B, 0x3C, 0x35, 0x32, 0x1F, 0x18, 0x11, 0x16, 0x03, 0x04, 0x0D, 0x0A,
    0x57, 0x50, 0x59, 0x5E, 0x4B, 0x4C, 0x45, 0x42, 0x6F, 0x68, 0x61, 0x66, 0x73, 0x74, 0x7D, 0x7A,
    0x89, 0x8E, 0x87, 0x80, 0x95, 0x92, 0x9B, 0x9C, 0xB1, 0xB6, 0xBF, 0xB8, 0xAD, 0xAA, 0xA3, 0xA4,
    0xF9, 0xFE, 0xF7, 0xF0, 0xE5, 0xE2, 0xEB, 0xEC, 0xC1, 0xC6, 0xCF, 0xC8, 0xDD, 0xDA, 0xD3, 0xD4,
    0x69, 0x6E, 0x67, 0x60, 0x75, 0x72, 0x7B, 0x7C, 0x51, 0x56, 0x5F, 0x58, 0x4D, 0x4A, 0x43, 0x44,
    0x19, 0x1E, 0x17, 0x10, 0x05, 0x02, 0x0B, 0x0C, 0x21, 0x26, 0x2F, 0x28, 0x3D, 0x3A, 0x33, 0x34,
    0x4E, 0x49, 0x40, 0x47, 0x52, 0x55, 0x5C, 0x5B, 0x76, 0x71, 0x78, 0x7F, 0x6A, 0x6D, 0x64, 0x63,
    0x3E, 0x39, 0x30, 0x37, 0x22, 0x25, 0x2C, 0x2B, 0x06, 0x01, 0x08, 0x0F, 0x1A, 0x1D, 0x14, 0x13,
    0xAE, 0xA9, 0xA0, 0xA7, 0xB2, 0xB5, 0xBC, 0xBB, 0x96, 0x91, 0x98, 0x9F, 0x8A, 0x8D, 0x84, 0x83,
    0xDE, 0xD9, 0xD0, 0xD7, 0xC2, 0xC5, 0xCC, 0xCB, 0xE6, 0xE1, 0xE8, 0xEF, 0xFA, 0xFD, 0xF4, 0xF3
}

local function CRC8Calcu(data,length)    		   --look-up table calculte CRC

    local crc8 = 0

    for i = 1,length do

        crc8 = CRC8Table[bit.bxor(crc8,data[i])+1]

	end
    return crc8
end

--*CRC8-校验码*(多项式=X8+X2+X+1(0x07),CRC8初8初始值固定为0为0x00)
local function Calc_CRC8(data, num)
    local crc, bits, bytes = 0x00, 0, 0
    for bytes = 1, num do
        crc = bit.bxor(crc, data[bytes])
        for bits = 8, 1, -1 do
            if (bit.band(crc, 0x80) ~= 0x0) then
                crc = bit.bxor(bit.clear(bit.lshift(crc, 1), 8, 9, 10), 0x07)
            else
                crc = bit.lshift(crc, 1)
            end
        end
    end
    return crc
end


--]]