local cbac = core:get_static_object("cbac");

local function enforce_army_cost_limit(character)
  if cm:char_is_mobile_general_with_army(character) then
    if cbac:is_army_punishable(character:military_force()) then
      local army_cqi = character:military_force():command_queue_index();
      local army_limit = cbac:get_army_limit(character);
      local army_cost = cbac:get_army_cost(character);

      if army_cost > army_limit or cbac:get_army_hero_count(character) > cbac:get_config("hero_cap") then
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

  core:add_listener(
    "CBAC_ApplyArmyPenalties",
    "FactionTurnStart",
    function(context) return context:faction():is_human() end,
    function(context)
      local current_faction = context:faction();
      cm:callback(function()
          enforce_faction_cost_limit(current_faction);
        end, 0.1)
    end,
    true
  );
end

-- MAIN --

local function main()
  add_listeners();
end

main();
