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
local actor_item = nil
local item_name_id = nil
local item_match_string = '.-has%spinged%s<%a+>(.-)</c>(%d)%.0$'
local radius = 250
local chat_open = false
local previous_size = 0

local rarities = {
    '<w>',
    '<g>',
    '<r>',
    '<or>',
    '<y>',
    '<p>',
    '<or>',
    '<w>'
}

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Ping", params['ping_enabled'])
    if clicked then
        params['ping_enabled'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local isChanged, keybind_value = ImGui.Hotkey("Ping Key", params['ping_key'])
    if isChanged then
        params['ping_key'] = keybind_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_always_draw_imgui(function()
    if ImGui.IsKeyPressed(params['ping_key']) and not chat_open then
        pinged = true
    end
end)

-- ========== Utils ==========

function find_player(m_id)
    local players = Helper.find_active_instance_all(gm.constants.oP)
    for _, p in ipairs(players) do
        if p.m_id == m_id then
            return p
        end
    end
end

-- ========== Main ==========

gm.pre_code_execute(function(self, other, code, result, flags)
    if code.name:match("oInit") then
        local message_list_size = gm.ds_list_size(self.chat_messages) 
        if message_list_size <= 0 or message_list_size == previous_size then return end

        previous_size = message_list_size
        
        local message = gm.ds_list_find_value(self.chat_messages, 0)
        if not message then return end
        
        local item_name, m_id = message.text:match(item_match_string)
        if not item_name then return end
        
        local player = Helper.get_client_player()
        if not player then return end

        actor_item = find_player(tonumber(m_id))
        
        item_name_id = item_name
        
        gm.ds_list_delete(self.chat_messages, 0)
        previous_size = message_list_size-1

        if player.m_id == 1 then
            local system_message = message.text:sub(1, -4)
            gm.chat_add_system_message(0, system_message)
        end

        chatPing = true
    end

end)


gm.pre_code_execute(function(self, other, code, result, flags)
    if not params['ping_enabled'] then return end
    
    if code.name:match("oHUD_Draw") then
        
        local player = Helper.get_client_player()
        if not player then return end
        
        if pinged then
            pinged = false
            
            
            local item = findItem(player)
            if not item then return end

            local object_ind = pingItem(self, item)
            if not object_ind then return end
            
            self.offscreen_object_indicators[#self.offscreen_object_indicators+1] = object_ind

            local message = player.user_name.." has pinged <w>"..item.text1.."</c>"

            if item.tier then 
                message = player.user_name.." has pinged "..rarities[item.tier+1]..item.text1.."</c>"
            end

            if player.m_id == 1 then 
                gm.chat_add_system_message(0, message)
            end

            player:net_send_instance_message(4, message..player.m_id)
        end
        
        if chatPing then
            chatPing = false
            
            local item = findItem(actor_item, item_name_id)
            if not item then return end
            
            local object_ind = pingItem(self, item)
            if not object_ind then return end

            self.offscreen_object_indicators[#self.offscreen_object_indicators+1] = object_ind
        end
    end
end)

function findItem(actor, item_name)
    if not actor then return end

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
