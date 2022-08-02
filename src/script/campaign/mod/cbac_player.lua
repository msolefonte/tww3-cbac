local cbac = core:get_static_object("cbac");
local exceptions = {
  free_military_force_types = {
    "DISCIPLE_ARMY",
    "OGRE_CAMP"
  },
  free_military_force_effects = {
    "wh2_dlc12_bundle_underempire_army_spawn" -- The Vermintide army
  }
}

-- COST LIMITS --

local function is_army_punishable(military_force)
  for _, free_military_force_type in pairs(free_military_force_types) do
    if free_military_force_type == military_force:force_type():key() then
      return false;
    end
  end

  for _, free_military_force_effect in pairs(free_military_force_effects) do
    return not military_force:has_effect_bundle(free_military_force_effect);
  end

  return true;
end

local function enforce_army_cost_limit(character)
  if cm:char_is_mobile_general_with_army(character) then
    if is_army_punishable(character:military_force()) then
      local army_cqi = character:military_force():command_queue_index();
      local army_limit = cbac:get_army_limit(character);
      local army_cost = cbac:get_army_cost(character);

      if (army_cost > army_limit) or (cbac:get_army_hero_count(character) > cbac:get_config("hero_cap")) then
        cbac:log("Army (" .. army_cqi .. ") is over cost limit (" .. army_limit .. "), will be punished!");
        cm:apply_effect_bundle_to_force("cbac_army_cost_limit_penalty", army_cqi, 1);
        return;
      end

      if army_cost <= army_limit then
        cbac:log("Army (" .. army_cqi .. ") is not over cost limit, will remove penalty!");
        cm:remove_effect_bundle_from_force("cbac_army_cost_limit_penalty", army_cqi);
      end
    end
  end
end

local function enforce_faction_cost_limit(faction)
  for i = 0, faction:character_list():num_items() - 1 do
    enforce_army_cost_limit(faction:character_list():item_at(i));
  end
end

local function generate_tooltip_text_army_cost(character)
  local lord_rank = character:rank();

  local limit_rank = cbac:get_config("limit_rank");
  local limit_step = cbac:get_config("limit_step");
  local limit_deceleration = cbac:get_config("limit_deceleration");
  local next_limit_increase = limit_step - ((math.floor(lord_rank/limit_rank)) * limit_deceleration);
  if next_limit_increase < 0 then next_limit_increase = 0 end

  local army_cost = cbac:get_army_cost(character);
  local army_queue_cost = cbac:get_army_queued_units_cost();
  local army_limit = cbac:get_army_limit(character);
  local hero_count = cbac:get_army_hero_count(character);
  local supply_factor = cbac:get_army_supply_factor(character, 0);

  local zoom_component = find_uicomponent(core:get_ui_root(), "main_units_panel", "button_focus");
  if not zoom_component then
    return;
  end

  local tooltip_text = "Army current point cost: " .. army_cost .. " (Limit: " .. army_limit .. ")";
  if army_queue_cost > 0 then
    tooltip_text = tooltip_text .. "\nProjected point cost after recruitment: " .. (army_cost + army_queue_cost);
  end
  tooltip_text = tooltip_text .. (cbac:get_character_cost_string(character));
  if (cbac:get_config("dynamic_limit")) then
    tooltip_text = tooltip_text .. "\nLimit rises every " .. limit_rank .. " lord levels. Next increase: " .. next_limit_increase;
  end
  if (army_cost + army_queue_cost) > army_limit then
    tooltip_text = "[[col:red]]" .. tooltip_text .. "[[/col]]";
  end
  if character:faction():is_human() and (hero_count) > cbac:get_config("hero_cap") then
    tooltip_text = tooltip_text .. "\n[[col:red]]" .. "This army has too many heroes in it!" .. "[[/col]]";
  end

  -- TODO SHOULD BE REMOVED?
  if character:faction():is_human() and (cbac:get_config("supply_lines")) then
    if not cbac:supply_lines_affect_faction(character:faction()) then
      tooltip_text = tooltip_text .. "\n\nThis faction does not use Supply Lines.";
    else
      -- TODO HARDCODED
      if character:character_subtype("wh2_main_def_black_ark") then
        tooltip_text = tooltip_text .. "\n\nBlack Arks do not contribute to the Supply Lines penalty";
      else
        tooltip_text = tooltip_text .. "\n\nArmy contributes at " .. (supply_factor * 100) .. "% to Supply Lines";
        if army_queue_cost > 0 then
          local supply_with_queued = cbac:get_army_supply_factor(character, army_queue_cost);
          tooltip_text = tooltip_text .. " (will be " .. (supply_with_queued * 100) .. "%)";
        end
      end
    end
  end

  zoom_component:SetTooltipText(tooltip_text, true);
end

local function set_tooltip_text_garrison_cost(cqi)
  local zoom_component = find_uicomponent(core:get_ui_root(), "main_settlement_panel_header", "button_info");
  if not zoom_component then
    return;
  end

  local tooltip_text = "";
  if cqi == -1 then
    tooltip_text = "Selected region has no garrison.";
  else
    local army_cost = cbac:get_garrison_cost(cqi);
    tooltip_text = "The units in the garrison of the selected settlement cost " .. army_cost .. " points. Garrisons have no limit.";
  end
  zoom_component:SetTooltipText(tooltip_text, true)
end

local function set_tooltip_text_garrison_cost_if_required(region)
  if not region:is_abandoned() then
    local garrison_commander = cm:get_garrison_commander_of_region(region);
    if garrison_commander then
      local army = garrison_commander:military_force();
      cm:callback(function()
          set_tooltip_text_garrison_cost(army:command_queue_index());
        end, 0.1)
    end
  end
end

-- SUPPLY LINES --

-- TODO SHOULD BE REMOVED?
local function apply_supply_lines(faction)
  local total_supply_lines_factor = 0;
  local character_list = faction:character_list();
  for i=0, character_list:num_items() - 1 do
    local character = character_list:item_at(i);
    if cm:char_is_mobile_general_with_army(character) and not character:character_subtype("wh2_main_def_black_ark") then
      if is_army_punishable(character:military_force()) then
        total_supply_lines_factor = total_supply_lines_factor + cbac:get_army_supply_factor(character, 0);
      end
    end
  end

  -- One full army is free (or several partial armies that add up to one full army or less)
  total_supply_lines_factor = total_supply_lines_factor - 1;
  if total_supply_lines_factor < 0 then
    total_supply_lines_factor = 0;
  end

  -- Base penalty is +15% unit upkeep on VH and Legendary
  local base_supply_lines_penalty = 4;
  -- Modify it for easy difficulties
  local combined_difficulty = cm:model():combined_difficulty_level()
  if combined_difficulty == -1 then  -- Hard
    base_supply_lines_penalty = 3;
  elseif combined_difficulty == 0 then  -- Normal
    base_supply_lines_penalty = 2;
  elseif combined_difficulty == 1 then  -- Easy
    base_supply_lines_penalty = 1;
  end

  local effect_strength = math.ceil(total_supply_lines_factor * base_supply_lines_penalty);
  local supply_lines_effect_bundle = cm:create_new_custom_effect_bundle("CBAC_supply_lines");
  supply_lines_effect_bundle:add_effect("wh_main_effect_force_all_campaign_upkeep", "force_to_force_own_factionwide", effect_strength);
  supply_lines_effect_bundle:set_duration(0);
  cm:apply_custom_effect_bundle_to_faction(supply_lines_effect_bundle, faction);
end

-- LISTENERS --

local function add_listeners()
  core:add_listener(
    "CBAC_MCTPanelOpened",
    "MctPanelOpened",
    true,
    function()
      cbac:block_mct_settings_if_required();
    end,
    true
  );

  core:add_listener(
    "CBAC_ArmyCostTooltip",
    "CharacterSelected",
    function(context)
      return context:character():has_military_force();
    end,
    function(context)
      local character = context:character();
      cm:set_saved_value("cbac_last_selected_char_cqi", character:command_queue_index());
      cbac:log("Selected character's CQI: " .. character:command_queue_index());
      cm:callback(function()
          generate_tooltip_text_army_cost(character);
        end, 0.1)
    end,
    true
  );

  core:add_listener(
    "CBAC_GarrisonCostTooltip",
    "SettlementSelected",
    true,
    function(context)
      set_tooltip_text_garrison_cost_if_required(context:garrison_residence():region());
    end,
    true
  );

  core:add_listener(
    "CBAC_NormalUnitDisbandedEvent",
    "UnitDisbanded",
    function(context)
      return cm.campaign_ui_manager:is_panel_open("units_panel") and context:unit():faction():is_human();
    end,
    function()
      cm:callback(function()
          enforce_faction_cost_limit(cm:model():world():whose_turn_is_it());
        end, 0.1)
    end,
    true
  );

  core:add_listener(
    "CBAC_GeneralDisbandedEvent",
    "CharacterConvalescedOrKilled",
    function(context)
      return cm:char_is_mobile_general_with_army(context:character());
    end,
    function()
      cm:set_saved_value("cbac_last_selected_char_cqi", "");
    end,
    true
  );

  core:add_listener(
    "CBAC_UnitMergedEvent",
    "UnitMergedAndDestroyed",
    function(context)
      return cm.campaign_ui_manager:is_panel_open("units_panel") and context:unit():faction():is_human();
    end,
    function(context)
      cm:callback(function()
          enforce_faction_cost_limit(cm:model():world():whose_turn_is_it());
        end, 0.1)
    end,
    true
  );

  -- Catch all clicks to refresh the army cost tooltip if the units_panel is open
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
                generate_tooltip_text_army_cost(last_selected_character);
              end
            end
          end
        end, 0.3)
    end,
    true
  );

  core:add_listener(
    "CBAC_ApplyArmyPenalties",
    "FactionTurnStart",
    function(context) return (context:faction():is_human()) end,
    function(context)
      local current_faction = context:faction();
      cm:callback(function()
          enforce_faction_cost_limit(current_faction);
        end, 0.1)
    end,
    true
  );

  core:add_listener(
    "CBAC_SupplyLines",
    "FactionTurnEnd",
    function(context)
      return (context:faction():is_human())
    end,
    function(context)
      local faction = context:faction();
      if (cbac:get_config("supply_lines")) then
        if cbac:supply_lines_affect_faction(faction) then
          apply_supply_lines(faction);
        end
      end
    end,
    true
  );
end

local function main()
  add_listeners();
end

main();
