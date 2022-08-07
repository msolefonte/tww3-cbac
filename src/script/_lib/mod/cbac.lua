local cbac = {};
local config = {
  army_limit_player = 10500,
  army_limit_ai = 12000,
  army_limit_fl_bonus = 0,
  dynamic_limit = true,
  limit_rank = 2,
  limit_step = 1000,
  limit_deceleration = 50,
  hero_cap = 2,
  supply_lines = false,
  upgrade_ai_armies = false,
  upgrade_grace_period = 20,
  auto_level_ai_lords = 3,
  logging_enabled = false
};
local exceptions = {
  free_factions = {
    "wh2_dlc10_def_blood_voyage"
  },
  free_heroes = {
    "wh_dlc07_brt_cha_green_knight_0",
    "wh_dlc06_dwf_cha_master_engineer_ghost_0",
    "wh_dlc06_dwf_cha_runesmith_ghost_0",
    "wh_dlc06_dwf_cha_thane_ghost_0",
    "wh_dlc06_dwf_cha_thane_ghost_1"
  },
  free_military_force_types = {
    "DISCIPLE_ARMY",
    "OGRE_CAMP"
  },
  free_military_force_effects = {
    "wh2_dlc12_bundle_underempire_army_spawn" -- The Vermintide army
  },
  free_units = {
    "wh_dlc07_brt_cha_green_knight_0"
  },
  custom_heroes = {
    "wh2_dlc11_cst_inf_count_noctilus_0",
    "wh2_dlc11_cst_inf_count_noctilus_1"
  },
  supply_lines_free_factions = {
    "wh2_dlc13_lzd_spirits_of_the_jungle"
  },
  supply_lines_free_subcultures = {
    "wh_dlc03_sc_bst_beastmen",
    "wh_main_sc_brt_bretonnia",
    "wh2_dlc09_sc_tmb_tomb_kings",
    "wh_main_sc_chs_chaos"
  }
}

-- UTILS --

function table.contains(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true;
    end
  end
  return false;
end

-- GENERIC --

function cbac:log(str)
  if cbac:get_config("logging_enabled") then
    local log_file = io.open("wolfy_mods_log.txt","a");
    log_file:write("\n[cbac] " .. str);
    log_file:flush();
    log_file:close();
  end
end

function cbac:gls(localised_string_key)
  return common.get_localised_string("cbac_" .. localised_string_key);
end

function cbac:get_config(config_key)
  if get_mct then
    local mct = get_mct();

    if mct ~= nil then
      local mod_cfg = mct:get_mod_by_key("wolfy_cost_based_army_caps");
      return mod_cfg:get_option_by_key(config_key):get_finalized_setting();
    end
  end

  return config[config_key];
end

function cbac:block_mct_settings_if_required()
  if get_mct then
    local mct = get_mct();

    if mct ~= nil then
      local mod_cfg = mct:get_mod_by_key("wolfy_cost_based_army_caps");
      if (mod_cfg:get_option_by_key("settings_locked"):get_finalized_setting()) then
        mod_cfg:get_option_by_key("army_limit_player"):set_read_only(true);
        mod_cfg:get_option_by_key("army_limit_ai"):set_read_only(true);
        mod_cfg:get_option_by_key("army_limit_fl_bonus"):set_read_only(true);
        mod_cfg:get_option_by_key("dynamic_limit"):set_read_only(true);
        mod_cfg:get_option_by_key("limit_rank"):set_read_only(true);
        mod_cfg:get_option_by_key("limit_step"):set_read_only(true);
        mod_cfg:get_option_by_key("limit_deceleration"):set_read_only(true);
        mod_cfg:get_option_by_key("hero_cap"):set_read_only(true);
        mod_cfg:get_option_by_key("supply_lines"):set_read_only(true);
        mod_cfg:get_option_by_key("upgrade_grace_period"):set_read_only(true);
        mod_cfg:get_option_by_key("upgrade_ai_armies"):set_read_only(true);
        mod_cfg:get_option_by_key("auto_level_ai_lords"):set_read_only(true);
      end
    end
  end
end

-- DEFINITIONS AND EXCEPTIONS --

function cbac:is_army_punishable(military_force)
  for _, free_military_force_type in pairs(exceptions.free_military_force_types) do
    if free_military_force_type == military_force:force_type():key() then
      return false;
    end
  end

  for _, free_military_force_effect in pairs(exceptions.free_military_force_effects) do
    return not military_force:has_effect_bundle(free_military_force_effect);
  end

  return true;
end

function cbac:is_faction_punisheable(faction)
  return faction:name() ~= "rebels" and not faction:name():find("_intervention")
    and not faction:name():find("_incursion")
    and not table.contains(exceptions.free_factions, faction:name());
end

function cbac:is_hero(unit_key)
  return string.find(unit_key, "_cha_") or table.contains(exceptions.custom_heroes, unit_key);
end

function _is_free_unit(unit_key)
  return table.contains(exceptions.free_units, unit_key);
end

function _is_free_hero(unit_key)
  return table.contains(exceptions.free_heroes, unit_key);
end

-- COST-BASED ARMY CAPS --

function cbac:get_unit_cost(unit)
  if _is_free_unit(unit:unit_key()) then
    return 0;
  else
    return unit:get_unit_custom_battle_cost();
  end
end

function cbac:get_unit_cost_from_key(unit_key)
  if _is_free_unit(unit_key) then
    return 0;
  else
    return cco("CcoMainUnitRecord", unit_key):Call("Cost");
  end
end

function cbac:get_hero_cost(unit)
  if cbac:is_hero(unit:unit_key()) and not _is_free_hero(unit:unit_key()) then
    return 1;
  end

  return 0;
end

function cbac:get_army_cost(character)
  if not character:has_military_force() then
    return -1;
  end

  local army_cost = 0;
  local unit_list = character:military_force():unit_list();
  for i = 0, unit_list:num_items() - 1 do
    army_cost = army_cost + cbac:get_unit_cost(unit_list:item_at(i));
  end

  return army_cost;
end

function cbac:get_army_limit(character)
  local army_limit;
  if character:faction():is_human() then
    army_limit = cbac:get_config("army_limit_player");
  else
    army_limit = cbac:get_config("army_limit_ai");
  end

  if character:is_faction_leader() then
    army_limit = army_limit + cbac:get_config("army_limit_fl_bonus");
  end

  if (cbac:get_config("dynamic_limit")) then
    local lord_rank = character:rank();
    local limit_rank = cbac:get_config("limit_rank");
    local limit_step = cbac:get_config("limit_step");
    local limit_deceleration = cbac:get_config("limit_deceleration");

    local total_deceleration_factor = 0;
    local number_of_steps = (math.floor(lord_rank / limit_rank)) - 1;

    for step=1, number_of_steps, 1 do
      if (limit_deceleration * step <= limit_step) then
        total_deceleration_factor = total_deceleration_factor + (limit_deceleration * step);
      else
        total_deceleration_factor = total_deceleration_factor + limit_step;
      end
    end

    army_limit = army_limit + ((math.floor(lord_rank / limit_rank)) * limit_step) - total_deceleration_factor;
  end

  return army_limit;
end

function cbac:get_army_hero_count(character)
  if not character:has_military_force() then
    return -1;
  end

  local army_hero_count = -1;
  local unit_list = character:military_force():unit_list();
  for i = 0, unit_list:num_items() - 1 do
    army_hero_count = army_hero_count + cbac:get_hero_cost(unit_list:item_at(i));
  end

  return army_hero_count;
end

function cbac:get_garrison_cost(cqi)
  local garrison_cost = 0;
  local unit_list = cm:get_military_force_by_cqi(cqi):unit_list();
  for i = 0, unit_list:num_items() - 1 do
    garrison_cost = garrison_cost + cbac:get_unit_cost(unit_list:item_at(i));
  end

  return garrison_cost;
end

function cbac:get_army_queued_units_cost()  -- TODO CHECK NURGLE AND ROR
  local queued_units_cost = 0;

  local army = find_uicomponent_from_table(core:get_ui_root(), {"units_panel", "main_units_panel", "units"})
  if army then
    for i = 0, army:ChildCount() - 1 do
      local unit_card = UIComponent(army:Find(i));
      if unit_card:Id():find("Queued") then
        unit_card:SimulateMouseOn();

        local ok, err = pcall(function()
          local unit_info = find_uicomponent(core:get_ui_root(), "hud_campaign", "unit_information_parent",
                                             "unit_info_panel_holder_parent", "unit_info_panel_holder");
          local unit_key = string.gsub(string.gsub(unit_info:GetContextObjectId("CcoUnitDetails"),
                                                   "RecruitmentUnit_", ""), "_%d+_%d+_%d+_%d+$", "");
          local unit_cost = cbac:get_unit_cost_from_key(unit_key);

          cbac:log("Value of " .. unit_key .. ": " .. unit_cost);
          queued_units_cost = queued_units_cost + unit_cost;
        end)

        if not ok then
          cbac:log("Error reading a queued unit card: " .. unit_card:Id());
          cbac:log(tostring(err));
        end
        unit_card:SimulateMouseOff();
      end
    end
  end

  return queued_units_cost;
end

-- SUPPLY LINES --

function cbac:supply_lines_affect_faction(faction)
    return not (table.contains(exceptions.supply_lines_free_factions, faction:name()) or
                table.contains(exceptions.supply_lines_free_subcultures, faction:subculture()));
end

function cbac:get_army_supply_factor(character, added_cost)
  if not character:has_military_force() then
    return -1;
  end

  local army_cost = cbac:get_army_cost(character) + added_cost;
  local army_limit = cbac:get_army_limit(character);

  local supply_factor = 1;
  if (army_cost / army_limit) < 0.25 then
    supply_factor = 0.25;
  elseif (army_cost / army_limit) < 0.5 then
    supply_factor = 0.5;
  elseif (army_cost / army_limit) < 0.75 then
    supply_factor = 0.75;
  end

  return supply_factor;
end

core:add_static_object("cbac", cbac);
