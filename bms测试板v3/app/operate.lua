module(..., package.seeall)
require "items"
require "dcbus"
OpreaIndex=1
OpreaResult="OK"
local TestNumber = "0"
function OperaTrace()
    while true do  

        if dcbus.OpreaStart==1  then

            if  items.items_tab[OpreaIndex]:StartRelayTime()==false then
                items.items_tab[OpreaIndex]:operate()
                -- print("System is Running ..index",OpreaIndex)
            else
                if items.items_tab[OpreaIndex].res=="NG" and 
                    OpreaIndex~=9  and  
                    OpreaIndex~=10 and 
                    OpreaIndex~=11 and  
                    OpreaIndex~=13 and 
                    OpreaIndex~=2
                then
                    OpreaResult="NG"
                    print("测试失败项目",items.items_tab[OpreaIndex].name,OpreaIndex)
                end
                OpreaIndex=OpreaIndex+1
                if OpreaIndex>23 then
                    OpreaIndex=1
                    dcbus.OpreaStart=0
                end
            end
            --items.items_tab[OpreaIndex]:JudgeOperaResult()

            -- if OpreaIndex==23 then 
            --    items.items_tab[OpreaIndex]:StopRelayTime()
            -- end


        end
    
        sys.wait(250)
    end
end
local LenStatusTotal=0
function JudgeOperaResult()

    while true do
        
        LenStatusTotal=LenStatusTotal+1
        if LenStatusTotal > 5 and LenStatusTotal<= 11 then
            hwcfg.pin14(1)
            hwcfg.pin15(1) 
        elseif LenStatusTotal>11 then
            hwcfg.pin14(0)
            hwcfg.pin15(0) 
            LenStatusTotal=0
        end
        if  dcbus.OpreaStart==1 then
            items.items_tab[OpreaIndex]:JudgeOperaResult()
        end
        sys.wait(50) 
    end

end
function DisplayPoll()
    while true do
        if dcbus.DisplayStart==1 then
           -- print("Display is Running ..index",dcbus.DisplayIndex)
            if items.items_tab[dcbus.DisplayIndex]:DisplayPollTask() == "OK"
            or items.items_tab[dcbus.DisplayIndex].adr1==nil
            then
    
                dcbus.DisplayIndex=dcbus.DisplayIndex+1
                if dcbus.DisplayIndex>23 or 
                  (dcbus.DisplayIndex==2 and items.items_tab[1].res=="NG") or 
                  (dcbus.DisplayIndex==4 and items.items_tab[3].res=="NG") or
                  (dcbus.DisplayIndex==9 and items.items_tab[8].res=="NG") --or
                --   (dcbus.DisplayIndex==3 and items.items_tab[2].res=="NG" and
                --    OpreaResult=="NG")    
                then
                    print("当前disindex",dcbus.DisplayIndex,"测试结果",items.items_tab[2].res,OpreaResult)
                    local ResultAdr=0
                    if OpreaResult=="OK" then 
                         ResultAdr=0x104C
                    else 
                         ResultAdr=0x104D
                    end
                    dcbus.dcbus_frame_send(7,0xF1,ResultAdr,1)
                    -- modbus.
                    TestNumber=TestNumber+1
                    dcbus.DisplayIndex=1
                    dcbus.DisplayStart=0
                    dcbus.OpreaStart=0
                end
            end

        end
        

        if dcbus.TcpDataSendSignal==0 then
            print("测试成功,发送结果")
            dcbus.TcpDataSendSignal=1
            local t = os.date("*t")
            modbus.torigin.result=OpreaResult
            modbus.torigin.number="test_"..TestNumber.."_"..string.format("%04d-%02d-%02d %02d:%02d:%02d",
            t.year,t.month,t.day,t.hour,t.min,t.sec)
            modbus.torigin.time= (rtos.tick()-dcbus.OperaTimeTotal)/200           
            print("torigin.time",modbus.torigin.time)
            print(modbus.torigin.number)
        end

        

        sys.wait(50)
    end
end


function eatSoftDog()
    print("feed watch dog!")
    rtos.eatSoftDog()
end