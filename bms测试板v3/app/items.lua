module(..., package.seeall)

require "modbus"
require "dcbus"
require "operate"

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



OnceBeeRecvCommand=0
OnceBeeSendCommand=0
-- MicroSensorSendFlag=0
-- MicroSensorRecvFlag=0
Bluetooth=0
 function obj: operate()
    
    local cmd=3
    local len=0
    if      self.id==1 then len=4 
    elseif  self.id==2 then len=1
    elseif  self.id==3 then len=27
    elseif  self.id==4 then return
    elseif  self.id==5 then len=1 
    elseif  self.id==6 then len=1 
    elseif  self.id==7 then hwcfg.relay_set_val(0,0,1,0)
    elseif  self.id==8 then hwcfg.relay_set_val(0,1,0,0)
    elseif  self.id==9 then hwcfg.relay_set_val(0,0,0,0)
    
    elseif  self.id==10 then hwcfg.relay_set_val(1,0,1,0) len=0x03
    elseif  self.id==11 then hwcfg.relay_set_val(0,0,0,0)
    elseif  self.id==12 then hwcfg.relay_set_val(0,1,0,1) len=0x03
    elseif  self.id==13 then hwcfg.relay_set_val(0,0,0,0) 
    
    elseif  self.id==14 then hwcfg.Gpio_set_val(0,0,1,0)  len=0x03
    elseif  self.id==15 then hwcfg.Gpio_set_val(1,0,1,0)  len=0x03
    elseif  self.id==16 then hwcfg.Gpio_set_val(1,0,0,0)  len=0x03
    elseif  self.id==17 then hwcfg.Gpio_set_val(1,0,1,0)  len=0x03

    elseif  self.id==18 then 

        -- if  MicroSensorSendFlag==0 then
        --     MicroSensorSendFlag=1
        --     print("发送拆卸报警提示框")
        --     dcbus.dcbus_frame_send(7,0xF1,0x1055,1) 
        -- end
           len=0x03

    elseif  self.id==19 then hwcfg.Gpio_set_val(0,1,1,0)  len=0x03
    elseif  self.id==20 then hwcfg.Gpio_set_val(1,0,1,0)  len=0x03
    elseif  self.id==21 then hwcfg.Gpio_set_val(1,0,0,1)  len=0x03
    elseif  self.id==22 then hwcfg.Gpio_set_val(1,0,1,0)  len=0x03
    
    elseif  self.id==23 then 

        if  OnceBeeSendCommand==0 then  
            OnceBeeSendCommand=1    
            dcbus.dcbus_frame_send(7,0xF1,0x104B,1) 
            modbus.modbus_frame_send(5,self.adr2,1)
        end 
    end

    if len~=0 then  modbus.modbus_frame_send(cmd,self.adr2,len) end
   

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
           or self.res ~= "NG"  then
           self.sta=1
           print("超时时间...当前测试项",self.id)
           return true
        end
    end
    if (self.id == 23 and OnceBeeRecvCommand==0)
    --or (self.id == 18 and MicroSensorRecvFlag==0) 
    then
        self.sync = false
    end
    return false
end

local function CheckTheValue(val,min,max,typ)

    if     typ==0 then
        if type(val)=="string" then 
            return "NG" 
        end
        if  min and max then
            if val>=min and val<=max then 
                return "OK" 
            end
        else
            if val==0  then 
                return "OK" 
             end 
        end
    elseif typ==1 then
        if type(val)=="number" then 
           return "NG" 
        end
        if val=="OK" and min=="OK" then 
           return "OK"
        end

    elseif typ==2 then
        if type(val)~="string" then 
            if val==4  or val==8  or val==12 or val==14 
            or val==16 or val==17 or val==20 or val==24
            then
               return "OK"
            end
        end
    
    end
    return "NG"

end



local ChaMosSta=1
local DisMosSta=1
local CellNumSta="NG"
ZeroCurrClib="NG"

function obj:JudgeOperaResult()

    if     self.name == "Rs485"         then    if modbus.torigin.object_id~="000000000000000" then 
                                                self.res = modbus.torigin.object_id end
    elseif self.name == "Cells"         then    self.res = CheckTheValue(modbus.torigin.cells,nil,nil,2)  
                                                CellNumSta=self.res
    elseif self.name == "VoltDis"       then    self.res = CheckTheValue(CellNumSta,modbus.torigin.VoltDis,nil,1) 
    elseif self.name == "Temp"          then    self.res = CheckTheValue(modbus.torigin.mostemp,modbus.torigin.battemp,nil,1)
    elseif self.name == "Online"        then    self.res = modbus.torigin.online
    elseif self.name == "CurrZero"      then    self.res = ZeroCurrClib
    elseif self.name == "DisChaMos"     then    DisMosSta = hwcfg.getGpio18Fnc() 
                                                self.res =  CheckTheValue(DisMosSta,nil,nil,0)
                                                modbus.torigin.mosfet = self.res
                                                print("放电mos导通监测",DisMosSta,self.res)
    elseif self.name == "ChaRgeMos"     then    self.res =  CheckTheValue(DisMosSta,nil,nil,0)  
    elseif self.name == "CloseMos"      then    
    elseif self.name == "CurrCalib1"    then    self.res=modbus.torigin.cur_clib
    elseif self.name == "CurrCalib3"    then    self.res=modbus.torigin.cur_clib
    elseif self.name == "UnderVolt1"    then    if modbus.torigin.cells<14 then modbus.torigin.uvp1="OK" end 
                                                self.res=modbus.torigin.uvp1
    elseif self.name == "UnderVoltRec1" then    self.res=modbus.torigin.uvp1_rec 
    elseif self.name == "UnderVolt2"    then    self.res=CheckTheValue(modbus.torigin.uvp1,modbus.torigin.uvp2,nil,1)
    elseif self.name == "UnderVoltRec2" then    self.res=CheckTheValue(modbus.torigin.uvp1_rec,modbus.torigin.uvp2_rec,nil,1)
    elseif self.name == "VoltAverage"   then    self.res=modbus.torigin.balance
    elseif self.name == "OverVolt1"     then    if modbus.torigin.cells<14 then modbus.torigin.ovp1="OK" end 
                                                self.res=modbus.torigin.ovp1
    elseif self.name == "OverVoltRec1"  then    self.res=modbus.torigin.ovp1_rec
    elseif self.name == "OverVolt2"     then    self.res=CheckTheValue(modbus.torigin.ovp1,modbus.torigin.ovp2,nil,1)
    elseif self.name == "OverVoltRec2"  then    self.res=CheckTheValue(modbus.torigin.ovp1_rec,modbus.torigin.ovp2_rec,nil,1)
    elseif self.name == "Bee"           then    self.res=modbus.torigin.bee
    end
    

 
end




function obj: DisplayPollTask()
    
    if  not self.adr1 then  
        return "NG" 
    end
    local FrameLen=0 
    if Bluetooth==0 then
        FrameLen=0x17
    else
        FrameLen=0x14
    end
    if self.sta==0 and self.ack==0 then

       dcbus.dcbus_frame_send(17,0xF1,self.adr1,"测试中")

    elseif self.sta==1 and self.ack==1 then
       
       if self.id==1 and self.res ~= "NG" then 
           dcbus.dcbus_frame_send(FrameLen,0xF1,self.adr1,self.res)
       else
           dcbus.dcbus_frame_send(0x09,0xF1,self.adr1,self.res) 
       end

    elseif self.sta==1 and self.ack==2 then
       dcbus.dcbus_frame_send(7,0xF1,dcbus.ProGressAdress,dcbus.DisplayIndex*4+8)
    elseif self.sta==1 and self.ack==3 then
       if self.id==1 and self.res ~= "NG" then
          dcbus.dcbus_frame_send(FrameLen,0xF1,0x1052,self.res)
       end
       return "OK"
    end
    --print("屏应答帧",self.ack,"测试状态",self.sta)
    return "NG"
    
end

OpreaResult="OK"
function ClearAllOperaSignal()

    for index=1,23 do
        items_tab[index].sync = false
        items_tab[index].ack = 0
        items_tab[index].res = "NG"
        items_tab[index].sta = 0
        modbus.torigin[index]="NG"
       
    end
    for  key, _ in pairs(modbus.torigin) do
        modbus.torigin[key]="NG"
    end
        -- print(modbus.torigin.mostemp,modbus.torigin.battemp,modbus.torigin.VoltDis,modbus.torigin.ovp1,modbus.torigin.ovp1_rec)
        modbus.torigin.balance="OK"
        modbus.torigin.VoltDis="NG"
        ChaMosSta=1
        DisMosSta=1
        ZeroCurrClib="NG"
        OnceBeeSendCommand=0
        OnceBeeRecvCommand=0
        -- MicroSensorSendFlag=0
        -- MicroSensorRecvFlag=0
        Bluetooth=0
        dcbus.DisplayIndex=1
        dcbus.OpreaStart=0
        dcbus.DisplayStart=0
        operate.OpreaIndex=1
        operate.OpreaResult="OK"

        hwcfg.Gpio_set_val(1,0,1,0)
        hwcfg.relay_set_val(0,0,0,0)

end


items_tab = {}
items_tab[1]=new("Rs485",1,0x1002,100,0x410)
items_tab[2]=new("Cells",2,nil,200,0x01)
items_tab[3]=new("VoltDis",3,0x100A,30,0x07)
items_tab[4]=new("Temp",4,0x100F,30,nil)
items_tab[5]=new("Online",5,0x1014,80,0x25)
items_tab[6]=new("CurrZero",6,nil,300,0x25)
items_tab[7]=new("DisChaMos",7,nil,100,nil)
items_tab[8]=new("ChaRgeMos",8,0x1019,20,nil)
items_tab[9]=new("CloseMos",9,nil,20,nil)
items_tab[10]=new("CurrCalib1",10,nil,200,0x22)
items_tab[11]=new("CurrCalib2",11,nil,20,nil)
items_tab[12]=new("CurrCalib3",12,0x101E,200,0x22)
items_tab[13]=new("CurrCalib4",13,nil,20,nil)

items_tab[14]=new("UnderVolt1",14,nil,100,0x22)
items_tab[15]=new("UnderVoltRec1",15,nil,100,0x22)
items_tab[16]=new("UnderVolt2",16,0x1023,100,0x22)
items_tab[17]=new("UnderVoltRec2",17,0x1028,100,0x22)

items_tab[18]=new("VoltAverage",18,0x102D,80,0x22)

items_tab[19]=new("OverVolt1",19,nil,100,0x22)
items_tab[20]=new("OverVoltRec1",20,nil,100,0x22)
items_tab[21]=new("OverVolt2",21,0x1032,100,0x22)
items_tab[22]=new("OverVoltRec2",22,0x1037,100,0x22)


items_tab[23]=new("Bee",23,0x103C,5,0x401)
