module(..., package.seeall)
require "items"
require "lcd"
require"com_process"
require"xl2515"
require"can"
local RevLevel=1
local ChargerTestEnd=0
local MchargerAdr=0x08305110
local LchargerAdr=0x08098110
 function OperaTrace()
    while true do  
        
        if lcd.OpreateStart==1  then
            --print("BMS测试中")
            if  items.items_tab[lcd.OpreaIndex]:StartRelayTime()==false then
                items.items_tab[lcd.OpreaIndex]:operate()
               --print("System is Running ..index",lcd.OpreaIndex)
            else
                if items.items_tab[lcd.OpreaIndex].res=="NG" 
                then
                    lcd.OpreaResult="NG"
                end
                lcd.OpreaIndex=lcd.OpreaIndex+1

                -- if  (lcd.KeyStatus==2 and lcd.OpreaIndex>21)or   
                --     (lcd.KeyStatus==3 and lcd.OpreaIndex>21)
                -- then
                --      local ID=items.items_tab[lcd.OpreaIndex-1].adr2
                --      xl2515.send_buffer({id = ID,ide =true,rtr=false},0,0,0,0,0,0,0,0)
                --      print("关闭锁和充电器指令......")
                -- end

                if  (lcd.KeyStatus==1 and lcd.OpreaIndex>13)or      
                    (lcd.KeyStatus==2 and lcd.OpreaIndex>21)or   
                    (lcd.KeyStatus==3 and lcd.OpreaIndex>21)or 
                    (lcd.KeyStatus==4 and lcd.OpreaIndex>22)or
                    (lcd.KeyStatus==5 and lcd.OpreaIndex>23)or
                    (lcd.OpreaIndex==2 and lcd.OpreaResult=="NG")or 
                    (lcd.OpreaIndex==15 and lcd.OpreaResult=="NG")
                then  
                     lcd.OpreateStart=0
                    --  if lcd.KeyStatus==2 or lcd.KeyStatus==3 then
                    --     local ID=items.items_tab[lcd.DisplayIndex-1].adr2
                    --     xl2515.send_buffer({id = ID,ide =true,rtr=false},0x00,0x00,0x00,0x00,0x00,0x24)
                    --     print("关闭锁指令......")
                    --  end
                     if lcd.KeyStatus==4 and can.DianGuiType==1 then 
                        ChargerTestEnd=1 
                     elseif lcd.KeyStatus==4 and can.DianGuiType==2 then 
                        ChargerTestEnd=2
                     end
                     print("测试运行代码段结束......",lcd.KeyStatus,can.DianGuiType)
                end

            end 

        end

        hw_cfg.LED1(RevLevel)
        hw_cfg.LED2(RevLevel)
        RevLevel=bit.band(bit.bnot(RevLevel),1)

       
        -- elseif SchaEnd==2 then

        --     if SchaAde<0x08098C10  then
        --         SchaAde=SchaAde+0x100
            
        --     end
        --     xl2515.send_buffer({id =SchaAde,ide =true,rtr=false},0,0,0,0,0,0,0,0)
        --     if SchaAde>=0x08098C10 then 
        --         SchaEnd=0
        --         SchaAde=0x08098110
        --     end
        
        
        sys.wait(250)
     

    end
end
    
function CloseCharger()
    while true do
        if ChargerTestEnd==1 then 
            xl2515.send_buffer({id =MchargerAdr,ide =true,rtr=false},0,0,0,0,0,36,0,0)
            if MchargerAdr<0x08305510  then
                MchargerAdr=MchargerAdr+0x100
            elseif MchargerAdr>=0x08305510 then 
                ChargerTestEnd=0
                MchargerAdr=0x08305110
            end
        elseif ChargerTestEnd==2 then
            xl2515.send_buffer({id =LchargerAdr,ide =true,rtr=false},0,0,0,0,0,0,0,0)
            if LchargerAdr<0x08098C10 then
                LchargerAdr=LchargerAdr+0x100
            elseif LchargerAdr>=0x08098C10 then
                ChargerTestEnd=0
                LchargerAdr=0x08098110
            end
        end
        sys.wait(500)
    end
end


function JudgeResult()
    while true do  
    if  lcd.OpreateStart==1  then
    items.items_tab[lcd.OpreaIndex]:JudgeOperaResult()
    end

    sys.wait(50)
    end
end


function DisplayPoll()
    while true do
        if lcd.DisplayStart==1 then
            --print("Display is Running ..index",lcd.DisplayIndex)
            if items.items_tab[lcd.DisplayIndex]:DisplayPollTask() == "OK" then
                lcd.DisplayIndex=lcd.DisplayIndex+1
                
                if  (lcd.KeyStatus==1 and lcd.DisplayIndex>13)or      
                    (lcd.KeyStatus==2 and lcd.DisplayIndex>21)or   
                    (lcd.KeyStatus==3 and lcd.DisplayIndex>21)or 
                    (lcd.KeyStatus==4 and lcd.DisplayIndex>22)or
                    (lcd.KeyStatus==5 and lcd.DisplayIndex>23)or
                    (lcd.DisplayIndex==2  and lcd.OpreaResult=="NG")or
                    (lcd.DisplayIndex==15 and lcd.OpreaResult=="NG")
                then  
                    local ResultAdr=nil
                    if lcd.OpreaResult=="OK" then 
                         ResultAdr=0x10A1
                    else 
                         ResultAdr=0x10A4
                    end
                    lcd.dcbus_frame_send(7,0xF1,ResultAdr,1)

                    -- local ID=items.items_tab[lcd.DisplayIndex-1].adr2
                    -- xl2515.send_buffer({id = ID,ide =true,rtr=false},0,0,0,0,0,0,0,0)
                    -- print("关闭锁和充电器指令发送...")
                     if lcd.DisplayIndex>23 then lcd.DisplayIndex=23 end
                        lcd.DisplayStart=0
                    print("屏幕运行代码段结束......")
                    --lcd.key_status_check()


                end

            end

        end
        sys.wait(50)
    end
end
