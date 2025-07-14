module(..., package.seeall)
require"can"
require "xl2515"
require "com_process"
require "lcd"
require "bat_voltage"
local items = {}
local obj = {}
obj.__index = obj

local function obj_items(name,id,adr1,tim,adr2)
    local o = {
        name = name,
        id = id ,
        sync = false,
        ack = 0,
        res = "NG",
        adr1 = adr1,
        tim0= 0,
        time = tim,
        adr2 = adr2,
        sta = 0,
 
    }
    items[id] = setmetatable(o, obj)
    return items[id]
end




local function new(name,id,adr1,tim,adr2)

    if (type(id) ~= "number")or(type(name)~= "string") then
        print("item", "initialize params error")
        return nil
    end
    if  id <= 0  then
        print("item", "id params error")
        return nil
    end
    return obj_items(name,id,adr1,tim,adr2)

end


OnceBeeSendCommand=0
OnceBeeRecvCommand=0
OnceChaSendCommand=0
OnceChaRecvCommand=0
OnceDorRecvCommand=0
OnceDorSendCommand=0
MChargerId=0x08305010
MLockerId=0x08105010
index=1
adress=0x10BB
VoltlistFlag=0
 function obj: operate()
    
    local cmd
    local len
    if self.id<=13 and self.id~=8 and self.id~=9 then
        if  self.id==1 then  cmd=3 len=2
        elseif  self.id==2 then cmd=3 len=4
        elseif self.id>=3 and self.id<=6 then  cmd=3 len=1
        elseif self.id==7 then  cmd=3 len=25
        elseif self.id==10 then cmd=5 len=3 
        elseif self.id==11 then cmd=3 len=1 bat_voltage.bat_adc_ctrl(1)
        elseif self.id==12 then cmd=5 len=4 bat_voltage.bat_adc_ctrl(0) print("关闭mos")
        elseif self.id==13 then 
            if  OnceBeeSendCommand==0 then
                OnceBeeSendCommand=1  
                cmd=5 len=1
                lcd.dcbus_frame_send(7,0xF1,0x109E,1) 
                print("发送喇叭状态提示")
            elseif OnceBeeSendCommand==1 then
                OnceBeeSendCommand=2
                cmd=5 len=3
            elseif OnceBeeSendCommand==2 then
                return
            end
        end
        com_process.modbus_frame_send(cmd,self.adr2,len)
        
    elseif self.id==21 then --or self.id==22 then

        if OnceChaSendCommand==0 then 
            OnceChaSendCommand=1
            local canadr=0x08108010
            if lcd.KeyStatus==3 then canadr=0x08100010 end   
            self.adr2= bit.bor(canadr,bit.lshift(can.DialCodeaddr,8))
            if lcd.KeyStatus==3 then
               xl2515.send_buffer({id =self.adr2,ide =true,rtr=false},1,0X00,0X00,0X00,0x01,0xD8)
            elseif  lcd.KeyStatus==2 then
               xl2515.send_buffer({id =self.adr2,ide =true,rtr=false},1,0X00,0X00,0X00,0x00,0x00,0x00,0x00) 
            end
            lcd.dcbus_frame_send(7,0xF1,0x10B3,1) 
        end

    elseif self.id==22 then
       
        --com_process.Charger_Open_Decvice(0,255,50,0.5)
        -- local data={0x01,0x13,0x88,0x00,0x32}
         if can.DianGuiType==2 then
             
          
            if self.adr2<0x08098C10 then--and can.LChargerAck=="OK" then
                --  can.LChargerAck="NG"
                self.adr2=self.adr2+0x100
            elseif self.adr2>=0x08098C10 then return end
            xl2515.send_buffer({id =self.adr2,ide =true,rtr=false},1,0x88,0x13,0x00,0x00,0,0,0)

         elseif can.DianGuiType==1 then

            if MChargerId<0x08305510 then--and can.MChargerAck=="OK" then
                -- can.MChargerAck="NG"
                MChargerId=MChargerId+0x100
            elseif MChargerId>=0x08305510 then return end
            xl2515.send_buffer({id =MChargerId,ide =true,rtr=false},1,0x13,0x88,0x00,0x00,0x9D,0x6E,0)
       
         end

    elseif self.id==23 then
        if can.DianGuiType==2 then

            if  self.adr2<0x08108C10 then
                -- if can.OnceDorRvAck=="OK" then
                --     can.OnceDorRvAck="NG"
                    self.adr2=self.adr2+0x100
                -- end
            elseif self.adr2>=0x08108C10 then
                if  OnceDorSendCommand==0 then
                    OnceDorSendCommand=1
                    lcd.dcbus_frame_send(7,0xF1,0x10AD,1) 
                end
                return
            end
            xl2515.send_buffer({id =self.adr2,ide =true,rtr=false},1,0,0,0,0,0,0,0) 

        elseif can.DianGuiType==1 then

            if MLockerId<0x08105510 then--and can.MLockerAck=="OK" then
                -- can.MLockerAck="NG"
                MLockerId=MLockerId+0x100
            elseif MLockerId>=0x08105510 then
                if  OnceDorSendCommand==0 then
                    OnceDorSendCommand=1
                    lcd.dcbus_frame_send(7,0xF1,0x10AD,1) 
                end    
                return 
            end
            xl2515.send_buffer({id =MLockerId,ide =true,rtr=false},1,0X00,0X00,0X00,0x01,0xD8)
          
        end
  
    end

end



function obj:SetRelayTime(rlt)
     self.tim=rlt
end
function obj : StopRelayTime()
    self.sync = false
end
 


function obj:StartRelayTime()

    if self.sync == false then
        self.tim0 = rtos.tick()
        self.sync=true
    end
    if self.sync ==  true then
        self.sta=0
        if rtos.tick()-self.tim0 >= self.time*20 
           or self.res ~= "NG" then
           self.sta=1
           print("超时时间.........",self.name,"测试编号",self.id,"测试结果",self.res)
           return true
        end
    end
    if (self.id == 13 and OnceBeeRecvCommand==0) or 
       (self.id == 23 and OnceDorRecvCommand==0) or 
       (self.id == 21 and OnceChaRecvCommand==0) or 
       (self.id == 7  and VoltlistFlag==1)
    then
        print("id和vlist",self.id,VoltlistFlag)
        self.sync = false
    end
    return false

end

local function CheckTheValue(val,min,max,typ)
    --print("开始判断")
    if type(val) == "string" and val=="NG" then  return "NG"   
    elseif typ==0 then if val>=min and val<=max then return "OK" end
    elseif typ==1 then if val>min then return "OK" end
    elseif typ==2 then if val<max then return "OK" end
    elseif typ==3 then if val==1  then return "OK" end
    elseif typ==4 then return val 
    elseif typ==5 then if val=="BT206006015730QLSD73932863" then return "OK"  end 
    elseif typ==6 then if val==min then return"OK" end 
    end
    return "NG"

end

function obj:JudgeOperaResult()

    if  self.name == "Rs485" then
        print("RS485",com_process.Bat_Rs485_Tab.Num)
        self.res = CheckTheValue(com_process.Bat_Rs485_Tab.Num,1,30,0)
    elseif self.name == "IMEI" then
        
        self.res = CheckTheValue(com_process.Bat_Rs485_Tab.IMEI,nil,nil,4)
        print("IMEI",self.res)
    elseif self.name == "Signal" then
        print("Signal",com_process.Bat_Rs485_Tab.Signal)
       self.res = CheckTheValue(com_process.Bat_Rs485_Tab.Signal,0,nil,1)
    elseif self.name == "SOC" then
        print("SOC",com_process.Bat_Rs485_Tab.SOC)
       self.res = CheckTheValue(com_process.Bat_Rs485_Tab.SOC,0,100,0)
    elseif self.name == "SOE" then
        print("SOE",com_process.Bat_Rs485_Tab.SOE)
        self.res = CheckTheValue(com_process.Bat_Rs485_Tab.SOE,0,10000,0)
    elseif self.name == "IOC" then
        self.res = CheckTheValue(com_process.Bat_Rs485_Tab.IOC,0,1000,0)
    elseif self.name == "Cell_Min_Volt" then
        print("Cell_Min_Volt",com_process.Bat_Rs485_Tab.Cell_Min_Volt)
        if  CheckTheValue(com_process.Bat_Rs485_Tab.Cell_Min_Volt,2500,nil,1)=="OK" and VoltlistFlag==2 then
        self.res="OK"
        end

    elseif self.name == "Cell_Max_Volt" then
        print("Cell_Max_Volt",com_process.Bat_Rs485_Tab.Cell_Max_Volt)
        self.res = CheckTheValue(com_process.Bat_Rs485_Tab.Cell_Max_Volt,nil,4500,2)

    elseif self.name == "Cell_Dif_Volt" then
        print("Cell_Dif_Volt",com_process.Bat_Rs485_Tab.Cell_Dif_Volt)
        self.res = CheckTheValue(com_process.Bat_Rs485_Tab.Cell_Dif_Volt,nil,500,2)
    elseif self.name == "Charge_Current" then
        --print("Charge_Current",com_process.Bat_Rs485_Tab.Charge_Current)
        self.res = CheckTheValue(com_process.Bat_Rs485_Tab.Charge_Current,50,200,0)
    elseif self.name == "Mosfet_Open" then
        self.res = CheckTheValue(com_process.bat_voltage.get(),50,nil,1)
    elseif self.name == "Mosfet_Close" then
        self.res = CheckTheValue(com_process.bat_voltage.get(),nil,40,2)
    elseif self.name == "Bee" then
        self.res = com_process.Bat_Rs485_Tab.Bee
   

    elseif self.name == "Rs4851" then
        self.res = CheckTheValue(can.War_Can_Tab.Rs4851,nil,nil,3)
    elseif self.name == "Temp"  then
        self.res = CheckTheValue(can.War_Can_Tab.Temp,0,100,0)
    elseif self.name == "Voltage" then
        self.res = CheckTheValue(can.War_Can_Tab.Voltage,3000,7000,0)
    elseif self.name == "BitCode" then
        self.res = CheckTheValue(can.War_Can_Tab.BitCode,nil,nil,5)
    elseif self.name == "SOC1" then
        self.res = CheckTheValue(can.War_Can_Tab.SOC1,0,100,0)
    elseif self.name == "SOE1" then
        self.res = CheckTheValue(can.War_Can_Tab.SOE1,0,100,0)
    elseif self.name == "Charger485"  then
        self.res = CheckTheValue(can.War_Can_Tab.Charger485,5350,nil,6)
    elseif self.name == "Lock" then
        self.res = can.War_Can_Tab.Lock
        -- if self.res=="OK" then
        --     xl2515.send_buffer({id =self.adr2,ide =true,rtr=false},0,0,0,0,0,0,0,0)
        -- end
    elseif self.name == "Charger" then
        self.res= CheckTheValue(com_process.bat_voltage.get(),45,90,0)--can.War_Can_Tab.Charger

    elseif self.name == "OpenDoor" then
        self.res=can.War_Can_Tab.OpenDoor
        
end
end




function obj: DisplayPollTask()
    
    if self.sta==0 and self.ack==0 then

       local res={0xB2,0xE2,0xCA,0xD4,0xD6,0xD0,0x2E,0x2E,0x2E}
       lcd.dcbus_frame_send(17,0xF1,self.adr1,string.char(unpack(res)))

    elseif (self.sta==1 and self.ack==1) or 
           (VoltlistFlag==1 and com_process.Bat_Rs485_Tab.Cell_Min_Volt~="NG")
    then
        local res=self.res
        local len=9
        if self.id==2 and self.res~= "NG" then len=23
        elseif self.id==3 then  res=string.format("%d",com_process.Bat_Rs485_Tab.Signal)
        elseif self.id==4 then  res=string.format("%d%%/%dV",com_process.Bat_Rs485_Tab.SOC,math.floor(com_process.Bat_Rs485_Tab.Volt/100)) 
        elseif self.id==5 then  res=string.format("%dAh",com_process.Bat_Rs485_Tab.SOE/100)
        elseif self.id==6 then  res=string.format("%dAh",com_process.Bat_Rs485_Tab.IOC/10)  
        elseif self.id==7 then  res=string.format("%d",com_process.volt_table[index])
        
        if index<com_process.Bat_Rs485_Tab.Num+1 then
        index=index+1
        self.adr1=adress
        adress=adress+5
        elseif index==com_process.Bat_Rs485_Tab.Num+1  then 
        self.adr1=0x1076    
        end
        print("应答次数",self.ack)
        elseif self.id==8 then  res=string.format("%d-%dmV",com_process.MaxVoltNumber,com_process.Bat_Rs485_Tab.Cell_Max_Volt)
        elseif self.id==9 then  res=string.format("%dmV",com_process.Bat_Rs485_Tab.Cell_Dif_Volt)   
        end
        if self.id==7 and self.ack==com_process.Bat_Rs485_Tab.Num+1 then
        res=string.format("%d-%dmV",com_process.MinVoltNumber,com_process.volt_table[index])
        end
        lcd.dcbus_frame_send(len,0xF1,self.adr1,res)
     
    elseif self.sta==1 and self.ack==2 then
  
        local factor=0
        if lcd.KeyStatus==1  then 
        factor= lcd.DisplayIndex*7+9
        elseif lcd.KeyStatus==2 or lcd.KeyStatus==3 then 
        factor=(lcd.DisplayIndex-13)*13+9
        elseif lcd.KeyStatus==4 or lcd.KeyStatus==5 then 
        factor=100
        end
        lcd.dcbus_frame_send(7,0xF1,lcd.ProGressAdress,factor)

    elseif self.sta==1 and self.ack==3 then

        if self.id==6 then VoltlistFlag=1 end
        return "OK"

    end
    -- print("当前测试项",self.name,"应答次数",self.ack)
   
    return "NG"
end

-- OpreaResult="OK"
function ClearAllOperaSignal()
    
    OnceBeeSendCommand=0
    OnceBeeRecvCommand=0
    OnceChaSendCommand=0
    -- can.OnceDorRvAck="NG"
    -- can.LChargerAck="NG"
    -- can.MChargerAck="NG"
    -- can.MLockerAck="NG"
    -- can.M_DianGui=0
    can.DianGuiType=0
    MChargerId=0x08305010
    MLockerId=0x08105010
    OnceDorRecvCommand=0
    OnceDorSendCommand=0
    OnceChaRecvCommand=0
    index=1
    adress=0x10BB
    VoltlistFlag=0
    lcd.OpreaResult="OK"
    items_tab[22].adr2=0x08098010
    items_tab[23].adr2=0x08108010
    for index=1,23 do
        items_tab[index].sync = false
        items_tab[index].ack = 0
        items_tab[index].res = "NG"
        items_tab[index].sta = 0
        -- com_process.Bat_Rs485_Tab[index]="NG"
    end
    for  key, _ in pairs(com_process.Bat_Rs485_Tab) do
        com_process.Bat_Rs485_Tab[key]="NG"
    end
    for key,_ in pairs(can.War_Can_Tab) do 
        can.War_Can_Tab[key]="NG"
    end
    --lca.key_status_check()

end

items_tab = {}
items_tab[1]=new("Rs485",1,0x1053,80,0x00)
items_tab[2]=new("IMEI",2,0x1058,20,0x410)
items_tab[3]=new("Signal",3,0x1062,20,0x25)
items_tab[4]=new("SOC",4,0x1067,20,0x02)
items_tab[5]=new("SOE",5,0x106C,20,0x03)
items_tab[6]=new("IOC",6,0x1071,20,0x26)
items_tab[7]=new("Cell_Min_Volt",7,0x1076,20,0x09)
items_tab[8]=new("Cell_Max_Volt",8,0x107B,20,0x09)
items_tab[9]=new("Cell_Dif_Volt",9,0x1080,20,0x09)
items_tab[10]=new("Mosfet_Open",10,0x1085,20,0x401)
items_tab[11]=new("Charge_Current",11,0x108A,100,0x05)
items_tab[12]=new("Mosfet_Close",12,0x108F,50,0x401)
items_tab[13]=new("Bee",13,0x1094,20,0x401)

items_tab[14]=new("Rs4851",14,0x1053,100,nil)--1053
items_tab[15]=new("Temp",15,0x1058,50,nil)--1058
items_tab[16]=new("Voltage",16,0x1062,50,nil)
items_tab[17]=new("BitCode",17,0x1067,50,nil)
items_tab[18]=new("SOC1",18,0x106C,50,nil)
items_tab[19]=new("SOE1",19,0x1071,50,nil)
items_tab[20]=new("Charger485",20,0x1076,200,nil)
items_tab[21]=new("Lock",21,0x107B,50,0x08108010)

items_tab[22]=new("Charger",22,0x1076,200,0x08098010)
items_tab[23]=new("OpenDoor",23,0x1076,100,0x08108010)