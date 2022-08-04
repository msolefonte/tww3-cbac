local cbac = core:get_static_object("cbac");

-- ARMY COST --

local function _get_hero_cost_tt_text(character)
  local hero_count = cbac:get_army_hero_count(character);
  if character:faction():is_human() and (hero_count) > cbac:get_config("hero_cap") then
    return "[[col:red]]" .. cbac:gls("hero_limit_passed") .. "[[/col]]\n\n";
  end
  return "";
end

local function _get_character_cost_tt_text(character)
  if not character:has_military_force() then
    return "";
  end

  local unit_list = character:military_force():unit_list();
  local character_cost_string = "\n\n" .. cbac:gls("lord") .. ": " .. cbac:get_unit_cost(unit_list:item_at(0)) .. "\n" .. cbac:gls("heroes") .. ": 0";

  if unit_list:num_items() > 1 then
    character_cost_string = character_cost_string:sub(1, -2);
    for i = 1, unit_list:num_items() - 1 do
      if string.find(unit_list:item_at(i):unit_key(), "_cha_") then
        character_cost_string = character_cost_string .. cbac:get_unit_cost(unit_list:item_at(i)) .. "/";
      end
    end
    character_cost_string = character_cost_string:sub(1, -2);
  end

  return character_cost_string;
end

local function _get_dynamic_cost_tt_text(character, army_limit)
  if (cbac:get_config("dynamic_limit")) then
    local lord_rank = character:rank();

    local limit_rank = cbac:get_config("limit_rank");
    local limit_step = cbac:get_config("limit_step");
    local limit_deceleration = cbac:get_config("limit_deceleration");
    local next_limit_increase = limit_step - ((math.floor(lord_rank/limit_rank)) * limit_deceleration);

    if next_limit_increase > 0 then
      local next_level = math.floor((lord_rank + limit_rank) / limit_rank) * limit_rank;
      return "\n\n" .. cbac:gls("capacity_at_level") .. " " .. next_level .. ": " .. next_limit_increase + army_limit;
    end
    return "\n\n" .. cbac:gls("maximum_capacity_reached");
  end

  return "";
end

local function _get_army_cost_tt_text(character, army_cost)
  local army_limit = cbac:get_army_limit(character);
  local tt_text = cbac:gls("army_cost") .. ": " .. army_cost;

  local army_queue_cost = cbac:get_army_queued_units_cost();
  if army_queue_cost > 0 then
    tt_text = tt_text .. "([[col:yellow]]+" .. army_queue_cost .. "[[/col]])";
  end

  tt_text = tt_text .. "/" .. army_limit;
  tt_text = tt_text .. _get_character_cost_tt_text(character);
  tt_text = tt_text .. _get_dynamic_cost_tt_text(character, army_limit);

  if (army_cost + army_queue_cost) > army_limit then
    tt_text = "[[col:red]]" .. tt_text .. "[[/col]]";
  end

  return tt_text;
end

local function set_tt_text_army_cost(character)
  local zoom_component = find_uicomponent(core:get_ui_root(), "main_units_panel", "button_focus");
  if not zoom_component then
    return;
  end

  local army_cost = cbac:get_army_cost(character);
  local tt_text = "";

  if cbac:is_army_punishable(character:military_force()) then
    tt_text = _get_hero_cost_tt_text(character) .. _get_army_cost_tt_text(character, army_cost);

    -- TODO SHOULD BE ME MOVED
    local supply_factor = cbac:get_army_supply_factor(character, 0);
    if character:faction():is_human() and (cbac:get_config("supply_lines")) then
      if not cbac:supply_lines_affect_faction(character:faction()) then
        tt_text = tt_text .. "\n\n" .. cbac:gls("sl_faction_disabled");
      else
        -- TODO HARDCODED
        if character:character_subtype("wh2_main_def_black_ark") then
          tt_text = tt_text .. "\n\n" .. cbac:gls("sl_black_arks");
        else
          tt_text = tt_text .. "\n\n" .. cbac:gls("sl_army_contribution_1") .. (supply_factor * 100) .. "% " ..
                    cbac:gls("sl_army_contribution_2");
          local army_queue_cost = cbac:get_army_queued_units_cost();
          if army_queue_cost > 0 then
            local supply_with_queued = cbac:get_army_supply_factor(character, army_queue_cost);
            tt_text = tt_text .. " (" .. cbac:gls("sl_will_be") .. " " .. (supply_with_queued * 100) .. "%)";
          end
        end
      end
    end
  else
    tt_text = "Army cost: " .. army_cost;
    local army_queue_cost = cbac:get_army_queued_units_cost();
    if army_queue_cost > 0 then
      tt_text = tt_text .. "(+" .. army_queue_cost .. ")";
    end
    tt_text = tt_text .. "\n\n" .. cbac:gls("army_no_limit");
  end

  zoom_component:SetTooltipText(tt_text, true);
end

-- UNIT COSTS --

local function get_unit_costs_tt_text(unit_costs)
  local tt_text_chars = cbac:gls("unit_costs_breakdown") .. "\n";
  local tt_text_units = "";

  for unit_key, cost in pairs(unit_costs) do
    local unit_name = common.get_localised_string("land_units_onscreen_name_" .. unit_key);
    if cbac:is_hero(unit_key) then
      tt_text_chars = tt_text_chars .. "\n" .. unit_name .. ": " .. cost;
    else
      tt_text_units = tt_text_units .. "\n" .. unit_name .. ": " .. cost;
    end
  end

  return tt_text_chars .. tt_text_units;
end

local function set_tt_text_unit_costs(character)
  local zoom_component = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "tr_element_list",
                                          "button_info_holder", "button_info");
  if not zoom_component then
    return;
  end

  local unit_costs = {};
  local unit_list = character:military_force():unit_list();
  for i = 0, unit_list:num_items() - 1 do
    unit_costs[unit_list:item_at(i):unit_key()] = cbac:get_unit_cost(unit_list:item_at(i));
  end

  zoom_component:SetTooltipText(get_unit_costs_tt_text(unit_costs), true);
end

-- GARRISON COST --

local function set_tt_text_garrison_cost(cqi)
  local zoom_component = find_uicomponent(core:get_ui_root(), "main_settlement_panel_header", "button_info");
  if not zoom_component then
    return;
  end

  local tt_text;
  if cqi == -1 then
    tt_text = cbac:gls("garrison_disabled");
  else
    local army_cost = cbac:get_garrison_cost(cqi);
    tt_text = cbac:gls("garrison_cost_1") .. army_cost .. cbac:gls("garrison_cost_2");
  end

  zoom_component:SetTooltipText(tt_text, true)
end

local function set_tt_text_garrison_cost_if_required(region)
  if not region:is_abandoned() then
    local garrison_commander = cm:get_garrison_commander_of_region(region);
    if garrison_commander then
      local army = garrison_commander:military_force();
      cm:callback(function()
          set_tt_text_garrison_cost(army:command_queue_index());
        end, 0.1)
    end
  end
end

-- LISTENERS --

local function add_listeners()
  core:add_listener(
    "CBAC_ArmyCost",
    "CharacterSelected",
    function(context)
      return context:character():has_military_force();
    end,
    function(context)
      local character = context:character();
      cm:set_saved_value("cbac_last_selected_char_cqi", character:command_queue_index());
      cbac:log("Selected character's CQI: " .. character:command_queue_index());
      cm:callback(function()
          set_tt_text_army_cost(character);
          set_tt_text_unit_costs(character);
        end, 0.1)
    end,
    true
  );

  core:add_listener(
    "CBAC_ArmyCostCleanup",
    "CharacterSelected",
    function(context)
      return not context:character():has_military_force();
    end,
    function()
      cm:set_saved_value("cbac_last_selected_char_cqi", "");
    end,
    true
  );

  core:add_listener(
    "CBAC_GarrisonCost",
    "SettlementSelected",
    true,
    function(context)
      set_tt_text_garrison_cost_if_required(context:garrison_residence():region());
    end,
    true
  );

  -- Catch all clicks to refresh the army cost tt if the units_panel is open
  -- Fires also when player cancels recruitment of a unit, adds a unit to the queue etc
  core:add_listener(
    "CBAC_ClickEvent",
    "ComponentLClickUp",
    function(context)
      return cm.campaign_ui_manager:is_panel_open("units_panel");
    end,
    function(context)
      cm:callback(function()
          local last_selected_character = cm:get_character_by_cqi(cm:get_saved_value("cbac_last_selected_char_cqi"));
          if last_selected_character and last_selected_character ~= "" then
            if not last_selected_character:is_wounded() then
              if cm:char_is_mobile_general_with_army(last_selected_character) then
                set_tt_text_army_cost(last_selected_character);
                set_tt_text_unit_costs(last_selected_character);
              end
            end
          end
        end, 0.3)
    end,
    true
  );
end

-- MAIN --

local function main()
  add_listeners();
end

main();
