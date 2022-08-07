local cbac = core:get_static_object("cbac");

-- UTILS --

function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = cm:random_number(i);
    tbl[i], tbl[j] = tbl[j], tbl[i];
  end
  return tbl;
end

function get_table_keys(tbl)
  local keys = {};
  for key, _ in pairs(tbl) do
    table.insert(keys, key);
  end

  return keys;
end

-- AI --

local function populate_recruitment_pool(unit_list, recruitment_pool)
  for i = 1, unit_list:num_items() - 1 do
    local unit = unit_list:item_at(i);
    local unit_key = unit:unit_key();

    if recruitment_pool[unit_key] == nil and not cbac:is_hero(unit_key) then  -- Reduce CBAC (IO) calls to keep it optimal
      local unit_cost = cbac:get_unit_cost(unit);
      if unit_cost > 0 then
        cbac:log("Recruitment pool entry: " .. unit_key .. " -> " .. unit_cost);
        recruitment_pool[unit_key] = unit_cost;
      end
    end
  end
end

local function generate_recruitment_pool(faction)
  cbac:log("Generating recruitment pool");
  local recruitment_pool = {};

  local characters = faction:character_list();
  for i = 0, characters:num_items() - 1 do
    local character = characters:item_at(i);
    if cm:char_is_mobile_general_with_army(character) then
      populate_recruitment_pool(character:military_force():unit_list(), recruitment_pool);
    end
  end

  cbac:log("Recruitment pool generated. Size: " .. #get_table_keys(recruitment_pool));
  return recruitment_pool;
end

local function replace_unit(old_unit_key, new_unit_key, character_lookup, faction_name, reimbursement)
  cbac:log("Replacing " .. old_unit_key .. " with " .. new_unit_key);
  cm:remove_unit_from_character(character_lookup, old_unit_key);
  cm:grant_unit_to_character(character_lookup, new_unit_key);
  cm:treasury_mod(faction_name, reimbursement); -- Jadawin did not reimburse rebels, blood voyage nor Tomb Kings
end

local function downgrade_unit_and_get_savings(unit_list, unit_index, recruitment_pool, character_lookup, faction_name)
  local unit_key = unit_list:item_at(unit_index):unit_key();
  local unit_cost = recruitment_pool[unit_key];  -- Use existing pool to optimize CBAC (IO) calls

  if unit_cost ~= nil and unit_cost > 0 then
    cbac:log("Downgrading unit? " .. unit_key);
    local recruitment_pool_keys = get_table_keys(recruitment_pool);
    local offset = math.random(0, #recruitment_pool_keys - 1);

    for i = 0, #recruitment_pool_keys - 1 do
      local rec_unit_key = recruitment_pool_keys[(i + offset) % #recruitment_pool_keys + 1];
      if recruitment_pool[rec_unit_key] < unit_cost then
        local reimbursement = unit_cost - recruitment_pool[rec_unit_key];
        replace_unit(unit_key, rec_unit_key, character_lookup, faction_name, reimbursement);
        cbac:log("Yay! Points saved: " .. reimbursement);
        return reimbursement;
      end
    end
  end

  cbac:log("Nay! No points saved");
  return 0;
end

local function enforce_limit_on_ai_army(character, recruitment_pool, required_savings, faction_name)
  local army_is_over_limit = true;

  local unit_list = character:military_force():unit_list();
  local unit_indices = {}
  for i = 1, unit_list:num_items() - 1 do
    table.insert(unit_indices, i);
  end

  unit_indices = shuffle(unit_indices);
  for i = 1, #unit_indices do
    required_savings = required_savings - downgrade_unit_and_get_savings(unit_list, unit_indices[i], recruitment_pool,
                                                                         cm:char_lookup_str(character), faction_name);
    if required_savings <= 0 then
      cbac:log("This army is now under the cost limit, moving on.")
      army_is_over_limit = false;
      break
    end
  end

  if army_is_over_limit then
    cbac:log("Looped through all units in army, but it is still over limit. Will try again in the next turn!");
  end
end

local function check_ai_force_army_limit(faction, character)
  if cm:char_is_mobile_general_with_army(character) then
    local army_cost = cbac:get_army_cost(character);
    local army_limit = cbac:get_army_limit(character);

    local recruitment_pool;
    local recruitment_pool_generated = false;

    if army_cost > army_limit then
      if not recruitment_pool_generated then
        recruitment_pool = generate_recruitment_pool(faction);
        recruitment_pool_generated = true;
      end

      cbac:log("AI Army of faction " .. faction:name() .. " is over cost limit (" .. army_cost .. "/" .. army_limit ..
               "). Limits will be enforced!");
      enforce_limit_on_ai_army(character, recruitment_pool, army_cost - army_limit, faction:name());
    end
  end
end

local function check_ai_faction_army_limit(faction)
  cbac:log("Checking faction limit: " .. faction:name());
  if cbac:is_faction_punisheable(faction) then
    cbac:log("Faction " .. faction:name() .. " is punisheable");
    local characters = faction:character_list();
    for i = 0, characters:num_items() - 1 do
      check_ai_force_army_limit(faction, characters:item_at(i));
    end
  end
end

-- LISTENERS --

local function add_listeners()
  core:add_listener(
    "ArmyCostLimitsAI",
    "FactionTurnStart",
    function(context)
      return not context:faction():is_human();
    end,
    function(context)
      check_ai_faction_army_limit(context:faction());
    end,
    true
  );
end

-- MAIN --

local function main()
  add_listeners();
end

main();
