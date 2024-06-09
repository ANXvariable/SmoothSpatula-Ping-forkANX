log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        ping_key = "F",
        ping_enabled = true
    }

    params = Toml.config_update(_ENV["!guid"], params)
end)

local pinged = false
local chatPing = false
local item_name_id = nil
local otype = nil
local item_match_string = 'has%spinged%sthe%sitem%s'
local radius = 300
local chat_open = false

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Ping", params['ping_enabled'])
    if clicked then
        params['ping_enabled'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, isChanged = ImGui.InputText("Ping Key", params['ping_key'], 20)
    if isChanged then
        params['ping_key'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_always_draw_imgui(function()
    if ImGui.IsKeyPressed(ImGuiKey[params['ping_key']]) and not chat_open then
        pinged = true
    end
end)

-- ========== Main ==========

gm.pre_code_execute(function(self, other, code, result, flags)
    if not params['ping_enabled'] then return end
    
    if code.name:match("oHUD_Draw") then
        
        local player = Helper.get_client_player()
        if not player then return end
        
        if pinged then
            pinged = false
            
            
            local item = findItem(player)
            if not item then return end

            print(item.text1)

            local object_ind = pingItem(self, item)
            if not object_ind then return end
            
            self.offscreen_object_indicators[#self.offscreen_object_indicators+1] = object_ind

            Helper.add_chat_message(player, "has pinged the item "..item.text1)
            player:net_send_instance_message(4, "has pinged the item "..item.text1)
        end
        
        if chatPing then
            chatPing = false
            
            local item = findItem(player, item_name_id)
            if not item then return end

            print(item.text1)

            local object_ind = pingItem(self, item)
            if not object_ind then return end

            
            self.offscreen_object_indicators[#self.offscreen_object_indicators+1] = object_ind
        end
        
    end
end)

gm.pre_script_hook(gm.constants.chat_add_user_message, function(self, other, result, args)
    local actor = args[1].value
    local message = args[2].value

    local player = Helper.get_client_player()
    if not player or actor.m_id == player.m_id then return end

    local match_str = message:match(item_match_string)
    if match_str then return end

    item_name_id = message:gsub(item_match_string, '')

    if not item_name_id then return end

    chatPing = true
end)

-- gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
--     -- Scan the 15 most recent chat messages and check if they have net_send ids
--     local oInit = Helper.find_active_instance(gm.constants.oInit)
--     if oInit and gm.ds_list_size(oInit.chat_messages) > 0 then
--         for n = math.min(gm.ds_list_size(oInit.chat_messages) - 1, 15), 0, -1 do
--             local message = gm.ds_list_find_value(oInit.chat_messages, n)
--             print(message.text)

--             local match_str = message.text:match('%shas%spinged')

--             if not match_str then return end

--             print(message.text)

            
--         end
--     end
-- end)

function findItem(actor, item_name)
    local item_list = gm.ds_list_create()
    gm.ds_list_clear(item_list)

    gm.collision_circle_list(actor.x, actor.y, radius, gm.constants.pPickup, false, true, item_list, true)

    if gm.ds_list_size(item_list) == 0 then return end

    if not item_name then return gm.ds_list_find_value(item_list, 0) end

    for i = 0, gm.ds_list_size(item_list)-1 do
        local item = gm.ds_list_find_value(item_list, i)
        if item.text1 == item_name then return item end
    end

    return
end

function pingItem(self, item)
    if #self.offscreen_object_indicators ~= 0 then
        for _, ind in ipairs(self.offscreen_object_indicators) do
            if item.id == ind.inst.id then return nil end
        end
    end

    local indicator = gm.struct_create()

    indicator.sprite = item.sprite_index
    indicator.col = 12632256
    indicator.inst = item

    return indicator
end

gm.pre_code_execute(function(self, other, code, result, flags)
    if code.name:match("oInit") then
        chat_open = self.chat_talking
    end
end)
