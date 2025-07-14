 module(..., package.seeall)

-- require "attr"
-- require "user"
require "xl2515"
require"lcd"

local rece_list = {}
War_Can_Tab={}
War_Can_Tab.Rs4851="NG"
War_Can_Tab.Temp="NG"
War_Can_Tab.SOC1="NG"
War_Can_Tab.SOE1="NG"
War_Can_Tab.Charger="NG"
War_Can_Tab.Voltage="NG"
War_Can_Tab.OpenDoor="NG"
War_Can_Tab.BitCode="NG"
War_Can_Tab.Charger485="NG"
War_Can_Tab.Lock="NG"




local ImeiFromCan=""
local ImeiIdCount=0
DialCodeaddr=0
ChaRCodeaddr=0
ChargeVoltage=0
ChargeCurrent=0
OnceDorRvAck="NG"
-- MChargerAck="NG"
-- LChargerAck="NG"
-- MLockerAck="NG"
DianGuiType=0

local function Number_Area_Juadge(val,min,max,step)

    if val>=min and val<=min+step then
         return 1
    elseif val>=min+step+1   and val<=min+2*step+1 then
         return 2
    elseif val>=min+2*step+2 and val<=min+3*step+2 then
         return 3
    elseif val>=min+3*step+3 and val<=min+4*step+3 then
         return 4
    elseif val>=min+4*step+4 and val<=max    then
         return 5
    end
    return 0
end

local function recv_can_process (id,data)
    
   
        if lcd.KeyStatus==2 and bit.bor(id,0x0F)==0x1410108F then
        DialCodeaddr=bit.band(id,0xF)
        War_Can_Tab.Rs4851= string.byte(data,3)
        War_Can_Tab.Voltage = string.byte(data,6)*256+ string.byte(data,5)
        local SIGN = string.byte(data,8)
        local VAL  = string.byte(data,7)
        if SIGN==1 then  VAL=-VAL end
        War_Can_Tab.Temp = VAL
        print("电柜485:",War_Can_Tab.Rs4851,"电柜voltage:",War_Can_Tab.Voltage,"电柜temp:",War_Can_Tab.Temp,"地址码",DialCodeaddr)
    
        elseif lcd.KeyStatus==3 and bit.bor(id,0xFF)==0x141010FF then
        
        War_Can_Tab.Rs4851=bit.band(bit.rshift(string.byte(data,1),1),0x03)
        War_Can_Tab.Voltage = string.byte(data,3)+string.byte(data,4)*256
        if War_Can_Tab.Voltage ~= 0 then 
           DialCodeaddr=bit.band(id,0xFF) 
           ChaRCodeaddr=Number_Area_Juadge(DialCodeaddr,0x51,0x69,4)
           print("充电器编号",ChaRCodeaddr)
        end
        
        -- local SIGN = string.byte(data,6)
        -- local VAL  = string.byte(data,5)
        -- if SIGN==1 then  VAL=-VAL end
        local VAL = string.byte(data,5)+string.byte(data,6)*256
        if VAL>0x8000 then VAL=VAL-0x10000 end 
        War_Can_Tab.Temp = VAL/10
        print("电柜485:",War_Can_Tab.Rs4851,"电柜voltage:",War_Can_Tab.Voltage,"电柜temp:",War_Can_Tab.Temp,"地址",DialCodeaddr)
        

    -- elseif bit.band(id,0x0810108F)==id then
    --     War_Can_Tab.OpenDoor_CAN="OK"
    --     print("opendoor")

    elseif (bit.bor(id,0x0F)==0x1411108F and lcd.KeyStatus==2) or (bit.bor(id,0xFF)==0x141210FF and lcd.KeyStatus==3) then
        ImeiFromCan=data
        ImeiIdCount=bit.bor(ImeiIdCount,0x01)
        print("bit码1",ImeiFromCan)
    elseif (bit.bor(id,0x0F)==0x1412108F and lcd.KeyStatus==2) or (bit.bor(id,0xFF)==0x141310FF and lcd.KeyStatus==3) then
        ImeiFromCan=ImeiFromCan..data
        ImeiIdCount=bit.bor(ImeiIdCount,0x02)
        print("bit码2",ImeiFromCan)
    elseif (bit.bor(id,0x0F)==0x1413108F and lcd.KeyStatus==2) or (bit.bor(id,0xFF)==0x141410FF and lcd.KeyStatus==3) then
        ImeiFromCan=ImeiFromCan..data
        ImeiIdCount=bit.bor(ImeiIdCount,0x04)
        print("bit码3",ImeiFromCan)
    elseif (bit.bor(id,0x0F)==0x1414108F and lcd.KeyStatus==2) or (bit.bor(id,0xFF)==0x141510FF and lcd.KeyStatus==3) then
        ImeiFromCan=ImeiFromCan..data:sub(1,2)
        if ImeiIdCount==7 and ImeiFromCan~=nil then
            War_Can_Tab.BitCode=ImeiFromCan 
            -- ChargeCurrent=tonumber(ImeiFromCan:sub(10,11))
            -- ChargeVoltage=tonumber(ImeiFromCan:sub(12,14))/10
        end
        print("bit码4",ImeiFromCan)---"bt码电压",ChargeVoltage,"bt码电流",ChargeCurrent)
        ImeiFromCan=""
        ImeiIdCount=0

    elseif  bit.bor(id,0x0F)==0x1415108F  and lcd.KeyStatus==2 then        
      
            War_Can_Tab.SOC1=string.byte(data,5)*256+ string.byte(data,6)
            War_Can_Tab.SOE1=string.byte(data,7)*256+ string.byte(data,8)

        print("soc:",War_Can_Tab.SOC1,"soe:",War_Can_Tab.SOE1)

    elseif  bit.bor(id,0xFF)==0x141610FF and lcd.KeyStatus==3 then

            War_Can_Tab.SOC1=string.byte(data,3)
            War_Can_Tab.SOE1=string.byte(data,3)
        
        print("soc:",War_Can_Tab.SOC1,"soe:",War_Can_Tab.SOE1)

    elseif bit.bor(id,0x0F)==0x1429108F or bit.bor(id,0xFF)==0x143010FF then
        if  lcd.KeyStatus==4 then
             War_Can_Tab.Charger=string.byte(data,1)+string.byte(data,2)*256
        end
        War_Can_Tab.Charger485=string.byte(data,1)+string.byte(data,2)*256
                            +string.byte(data,3)+string.byte(data,4)*256--5350
        print("充电器电流:",War_Can_Tab.Charger,"充电器485",War_Can_Tab.Charger485)

    elseif bit.bor(id,0x0F)==0x0810108F then
        OnceDorRvAck="OK"
        print("开锁接收指令")

    elseif bit.bor(id,0xFF)==0x181010FF then
    -- elseif bit.bor(id,0xFF)==0x141210FF then
       local M_DianAdr=bit.band(id,0xFF)
       if M_DianAdr>=0x51 and M_DianAdr<0x69 then
          DianGuiType=1
       elseif M_DianAdr>=0x81 and M_DianAdr<=0x8C then
          DianGuiType=2
       end 
       print("当前电柜型号",DianGuiType)
    --    print("报文id",string.format("0X%x",id))
    -- elseif lcd.KeyStatus==4 and bit.bor(id,0xFF)==0x083010FF then
    --     MChargerAck="OK"
    --     print("M电柜充电器应答")
        
    -- elseif lcd.KeyStatus==4 and bit.bor(id,0xF)==0x0809108F then
    --     LChargerAck="OK"
    --     print("L电柜充电器应答")

    -- elseif lcd.KeyStatus==5 and bit.bor(id,0x081010FF) then
    --      MLockerAck="OK"
    --      print("M电柜锁应答")
end
end


sys.subscribe("mcp2515", function(len,buff,config)

    -- print("[CAN]","CAN接收的数据", string.format('%x',config.id),buff:toHex())
    -- local info = {}
    -- info.id = config.id
    -- info.data = buff
    -- if #rece_list > 300 then table.remove(rece_list, 1) end
    -- table.insert(rece_list,info)
    recv_can_process(config.id,buff)

end)    


function init()
    --sys.wait(1000)
    print("[CAN]", "开始CAN初始化")
    local mcp2515_spi= spi.SPI_1
    local mcp2515_cs= pio.P0_10
    local mcp2515_int=pio.P0_27
    spi_mcp2515 = spi.setup(spi.SPI_1,0,0,8,1625*1000,1)
    xl2515.init(spi.SPI_1,mcp2515_cs,mcp2515_int,0x03)
    print("[CAN]", "spi1",spi.SPI_1)
    print("[CAN]", "触发方式",cpu.INT_GPIO_POSEDGE,cpu.INT_GPIO_NEGEDGE)
end




