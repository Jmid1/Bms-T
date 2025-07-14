module(..., package.seeall)

require "socket"
require "misc"
require "attr"
require "sim"
require "tool"


Active = {}
Active.Result = 0x01 -- 结果
--
--
Device_id = nil
local socket_client = {}
local connect_flag = false
local send_fail = 0
local link_flag = false
local recv_queue = {}
local up_txn = 0
local re_txn = 0
local result_list = {}
local heart_up_flag = false
--

--- 初始化设备ID
local function device_id_init()
    local imei = misc.getImei()
    if imei == "" then return end
    Device_id = imei
    if attr.IS_Print then
        print("[TCP-N]", "imei",imei)
    end
end
--
--- 心跳包上传处理
local function heart_up()
    
    up_txn = os.time()
    local list = 
    {
        id = Device_id,
        mesId = up_txn
    }
    send(json.encode(list))
    return true
end
--
--
--- 测试结果上传处理
local function result_up()
    
    local resu = result_list[1]
    re_txn = os.time()
    local list = 
    {
        id = Device_id,
        mesId = re_txn,
        number = resu.number,
        time = resu.time,
        cells = resu.cells,
        result = resu.result,
        mosTemp = resu.mosTemp,
        batTemp = resu.batTemp,
        SvolGc1 = resu.SvolGc1,
        SvolGcR1 = resu.SvolGcR1,
        SvolGc2 = resu.SvolGc2,
        SvolGcR2 = resu.SvolGcR2,
        SvolGd1 = resu.SvolGd1,
        SvolGdR1 = resu.SvolGdR1,
        SvolGd2 = resu.SvolGd2,
        SvolGdR2 = resu.SvolGdR2,
        CurJz = resu.CurJz,
        balance = resu.balance,
        onine = resu.onine,
        bee = resu.bee
    }
    send(json.encode(list))
    return true
end
--
--
--
--
--- 网络功能监控
---@param ip string
---@param port string
local function monitor_task(ip, port)
    while Device_id == nil do 
        sys.wait(200) 
        device_id_init() 
    end

    local err_cnt = 0
    local conn_flag = true 
    local con_cnt = 0
    while true do
        err_cnt = 0
        while not socket.isReady() do
            sys.wait(1000)
            err_cnt = err_cnt + 1
            if err_cnt == 50 then
                if attr.IS_Print then
                    print("[TCP-N]", "selvert try net fly")
                end
                net.switchFly(true)
                sys.wait(10000)
                net.switchFly(false)
            elseif err_cnt >= 110 then
                err_cnt = 0
                if not attr.test_state_get() then
                    sys.restart("net isready error")
                end
            end
        end
        err_cnt = 0
        socket.setTcpResendPara(3, 8)
        socket_client = socket.tcp()
        conn_flag = true
        while not socket_client:connect(ip, port) do 
            sys.wait(2000) 
            if socket.isReady() then
                con_cnt = con_cnt + 1
                if con_cnt == 20 then
                    conn_flag = false
                    break
                elseif con_cnt >= 60 then
                    con_cnt = 0
                    if not attr.test_state_get() then
                        sys.restart("client connect error")
                    end
                end
            else
                err_cnt = err_cnt + 1
                if err_cnt == 5 then
                    conn_flag = false
                    break
                end
            end
            if attr.IS_Print then
                print("[TCP-N]", "selvert err cnt---",con_cnt,socket.isReady())
            end
        end
        if conn_flag then
            print("tcp_n selvert link")
            link_flag = true
            con_cnt = 0
            connect_flag = true
            send_fail = 0
            heart_up_flag = true
            while socket_client:asyncSelect(0) and connect_flag do end
            print("tcp_n selvert close")
        end
        link_flag = false
        socket_client:close()

        --net.switchFly(true)
        sys.wait(5000)
        --net.switchFly(false)
        if attr.IS_Print then
            print("[TCP-N]", "try selvert restart")
        end
    end
    
end
--
--
--- socket数据发送
---@param data any
function send(data)
    if link_flag then
        if #data < 3 then return end
        local res = false
        if type(data) == "string" then
            if attr.IS_Print then
                print("[TCP-N]", "模块上报数据:", data)
            end
            res = socket_client:asyncSend(data)
        elseif type(data) == "table" then
            local buff = string.char(unpack(data))
            if attr.IS_Print then
                print("[TCP-N]", "模块发生数据:", buff:toHex())
            end
            res = socket_client:asyncSend(buff)
        else
            res = socket_client:asyncSend(data)
        end

        if not res then
            if attr.IS_Print then
                print("[TCP-NET]", "send error")
            end
            send_fail = send_fail + 1
            if send_fail > 5 then
                send_fail = 0
                connect_flag = false
            end
        else
            send_fail = 0
        end
    end
end
--
--
--
--
--- 网络功能轮询任务
local function up_ind(flag, result)

    if flag == Active.Result then
        if #result_list > 20 then table.remove(result_list, 1) end
        table.insert(result_list, result)
        print("长度 result",#result_list)
    end

end
--
--
--- 网络功能轮询任务
local function poll_task()

    local heart_time = tool.tick()

    while true do
        if link_flag then 
                                
            --- 心跳信息上报处理
            if tool.dur_tick(heart_time) > 240000 or heart_up_flag then

                if attr.IS_Print then
                    print("[TCP-N]", "heart_upload...")
                end
                if heart_up() then 
                    heart_time = tool.tick()
                    local result, reply = sys.waitUntil("Heart_Ack", 5000)
                    if result then
                        if reply == 0x00 then
                            if attr.IS_Print then
                                print("[TCP-N]", "heart upload succeed")
                            end
                            heart_up_flag = false                            
                        else
                            if attr.IS_Print then
                                print("heart_upload failed 1")
                            end
                            sys.wait(1000)
                        end
                    else
                        if attr.IS_Print then
                            print("heart_upload failed 2")
                        end
                        heart_up_flag = true
                    end
                else
                    sys.wait(1000)
                end
            end
            
            --- 结果上报处理
            if #result_list > 0 then
                if attr.IS_Print then
                    print("[TCP-N]", "result upload ...",#result_list)
                end
                if result_up() then
                    local result, reply = sys.waitUntil("Result_Ack", 5000)
                    if result then
                        if reply == 0x00 then
                            table.remove(result_list, 1)
                            if attr.IS_Print then
                                print("[TCP-N]", "result upload succeed")
                            end
                        else
                            if attr.IS_Print then
                                print("[TCP-N]", "result upload failed_1")
                            end
                            sys.wait(1000)
                        end
                    else
                        if attr.IS_Print then
                            print("[TCP-N]", "result upload failed_2")
                        end
                    end
                end
            end
 
        end
        sys.wait(100)

    end
end
--
--- socket数据接收解析
---@param id any
local function recv(id)
    if socket_client.id == id then
        local buff = socket_client:asyncRecv()
        if attr.IS_Print then
            print("[TCP-N]", "服务器下发数据:", buff)
        end
        table.insert(recv_queue, buff)
    end
end
--
--- 网络接收处理任务
local function recv_task()

    while true do
        if #recv_queue > 0 then

            local buff = table.remove(recv_queue, 1)
            local tdata,result,errinfo = json.decode(buff)
            if result then
                if tdata["id"] == Device_id then
                    --user.serT_clear()
                    if tdata["mesId"] == up_txn then
                        sys.publish("Heart_Ack", 0x00)
                    elseif tdata["mesId"] == re_txn then
                        sys.publish("Result_Ack", 0x00)
                    end
                else
                    if attr.IS_Print then
                        print("[TCP-N]", "设备ID不匹配")
                    end       
                end
            else
                if attr.IS_Print then
                    print("[TCP-N]", "非json数据")
                end
            end
        end

        sys.wait(50)

    end
end
--
--
local rssi_cnt = 0
--- 获取信号强度
local function get_rssi()
    if attr.IS_Print then
        print("[TCP-N]", "rssi", net.getRssi())
    end
    --if net.getRssi() then
        --rssi = net.getRssi()
    --end
end
--
--
--
--- 网络功能初始化
function init()
    sys.taskInit(function ()
        net.startQueryAll(60000, 60000)

        sys.subscribe("IMEI_READY_IND", device_id_init)
        sys.subscribe("SOCKET_RECV", recv)
        sys.subscribe("UP_IND", up_ind)

        sys.timerLoopStart(get_rssi, 2000, "Time_GetRssi")

        local cnt = 0
        while not sim.getStatus() do
            sys.wait(200)
            cnt = cnt + 1
            if cnt > 600 then
                if attr.IS_Print then
                    print("TCP-NET", "NOT SIM......")
                end
                if not attr.test_state_get() then
                    sys.restart("NOT SIM--status")
                end
            end
        end
        cnt = 0
        local iccid_ = sim.getIccid()
        while iccid_ == nil do
            cnt = cnt + 1
            iccid_ = sim.getIccid()
            if cnt > 450 then
                if attr.IS_Print then
                    print("TCP-NET", "NOT SIM......")
                end
                if not attr.test_state_get() then
                    sys.restart("NOT SIM--iccid")
                end
            end
            sys.wait(200)
        end
        --local file_auto = attr.OTA_File
        --attr.update_state_set(1)
        --ota.request(file_auto)

        --if attr.IS_Print then
        --    print("[TCP-N]", "ICCID= ", iccid_)
        --end
        --iccid = tool.hex_str2table(iccid_, 1, #iccid_)

        local ip, port = "175.178.95.129","14336"
        sys.taskInit(monitor_task, ip, port)
        sys.taskInit(poll_task)
        sys.taskInit(recv_task)
    end)
end
--
--
--- 打开获取信号强度
function get_rssi_open()
    net.startQueryAll(60000, 60000)
    sys.timerLoopStart(get_rssi, 2000, "Time_GetRssi")
    rssi_cnt = 0
end
--
--
--- 关闭获取信号强度
function get_rssi_close()
    net.stopQueryAll()
    sys.timerStop(get_rssi, "Time_GetRssi")
end
--[[
sys.timerStart(function() 
    sys.publish("UP_IND", tcp_n.Active.Result,{number= 1,time = attr.test_state_get(),mosTemp = attr.test_cnt_get()})
    print("一次 result")
end, 20000)
--]]