local cbac = core:get_static_object("cbac");

local function apply_supply_lines(faction)
  local total_supply_lines_factor = 0;
  local character_list = faction:character_list();
  for i = 0, character_list:num_items() - 1 do
    local character = character_list:item_at(i);
    if cm:char_is_mobile_general_with_army(character) and not character:character_subtype("wh2_main_def_black_ark") then
      if cbac:is_army_punishable(character:military_force()) then
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
  local combined_difficulty = cm:model():combined_difficulty_level();
  if combined_difficulty == -1 then  -- Hard
    base_supply_lines_penalty = 3;
  elseif combined_difficulty == 0 then  -- Normal
    base_supply_lines_penalty = 2;
  elseif combined_difficulty == 1 then  -- Easy
    base_supply_lines_penalty = 1;
  end

  local effect_strength = math.ceil(total_supply_lines_factor * base_supply_lines_penalty);
  local supply_lines_effect_bundle = cm:create_new_custom_effect_bundle("CBAC_supply_lines");
  supply_lines_effect_bundle:add_effect("wh_main_effect_force_all_campaign_upkeep", "force_to_force_own_factionwide",
                                        effect_strength);
  supply_lines_effect_bundle:set_duration(0);
  cm:apply_custom_effect_bundle_to_faction(supply_lines_effect_bundle, faction);
end

-- LISTENERS --

local function add_listeners()
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

-- MAIN --

local function main()
  add_listeners();
end

main();
