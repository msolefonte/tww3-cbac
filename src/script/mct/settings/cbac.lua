if not get_mct then return end
local mct = get_mct();

if not mct then return end
local mct_mod = mct:register_mod("wolfy_cost_based_army_caps");

mct_mod:set_title("Cost-based Army Caps", false);
mct_mod:set_author("Wolfy & Jadawin");
mct_mod:set_description("MP-Style Cost Limit For All Armies", false);

local mct_section_base = mct_mod:add_new_section("1-cbac-base", "Base Options", false);

local option_cbac_army_limit_player = mct_mod:add_new_option("army_limit_player", "slider");
option_cbac_army_limit_player:set_text("Player Limit (Base)");
option_cbac_army_limit_player:set_tooltip_text("How many points per player army?");
option_cbac_army_limit_player:slider_set_min_max(3000, 40000);
option_cbac_army_limit_player:slider_set_step_size(500);
option_cbac_army_limit_player:set_default_value(10500);

local option_cbac_army_limit_ai = mct_mod:add_new_option("army_limit_ai", "slider");
option_cbac_army_limit_ai:set_text("AI Limit (Base)");
option_cbac_army_limit_ai:set_tooltip_text("How many points per AI army?");
option_cbac_army_limit_ai:slider_set_min_max(10000, 40000);
option_cbac_army_limit_ai:slider_set_step_size(500);
option_cbac_army_limit_ai:set_default_value(12000);

local option_cbac_hero_cap = mct_mod:add_new_option("hero_cap", "slider");
option_cbac_hero_cap:set_text("Allowed Heroes per Army");
option_cbac_hero_cap:set_tooltip_text("Exceeding this number of embedded heroes will trigger the same penalties as being over the cost limit.");
option_cbac_hero_cap:slider_set_min_max(0, 19);
option_cbac_hero_cap:slider_set_step_size(1);
option_cbac_hero_cap:set_default_value(2);

local option_cbac_settings_locked = mct_mod:add_new_option("settings_locked", "checkbox");
option_cbac_settings_locked:set_text("Lock settings during campaigns");
option_cbac_settings_locked:set_tooltip_text("If enabled, you can't change these settings during a campaign, only from the main menu.");
option_cbac_settings_locked:set_default_value(false);
option_cbac_settings_locked:set_read_only(true);

local mct_section_dl = mct_mod:add_new_section("2-cbac-dl", "Dynamic Limits Options", false);

local option_cbac_dynamic_limit = mct_mod:add_new_option("dynamic_limit", "checkbox");
option_cbac_dynamic_limit:set_text("Enable Dynamic Cost Limit");
option_cbac_dynamic_limit:set_tooltip_text("Limit increases with the level of the lord.");
option_cbac_dynamic_limit:set_default_value(true);

local option_cbac_limit_rank = mct_mod:add_new_option("limit_rank", "slider");
option_cbac_limit_rank:set_text("Lord level increase required to increase army limit");
option_cbac_limit_rank:set_tooltip_text("Every x levels gained, a lord's army's limit will go up (if limit is set to dynamic);.");
option_cbac_limit_rank:slider_set_min_max(1, 20);
option_cbac_limit_rank:slider_set_step_size(1);
option_cbac_limit_rank:set_default_value(2);

local option_cbac_limit_step = mct_mod:add_new_option("limit_step", "slider");
option_cbac_limit_step:set_text("Limit increase step size");
option_cbac_limit_step:set_tooltip_text("Every time a lord's level increase triggers a limit increase, it goes up by this amount (if limit is set to dynamic);.");
option_cbac_limit_step:slider_set_min_max(100, 5000);
option_cbac_limit_step:slider_set_step_size(100);
option_cbac_limit_step:set_default_value(1000);

local option_cbac_limit_deceleration = mct_mod:add_new_option("limit_deceleration", "slider");
option_cbac_limit_deceleration:set_text("Limit deceleration");
option_cbac_limit_deceleration:set_tooltip_text("At every step, the limit increase slows down by this amount, so that the limit rises fast at first, but the increase slows down at higher levels.");
option_cbac_limit_deceleration:slider_set_min_max(0, 2000);
option_cbac_limit_deceleration:slider_set_step_size(10);
option_cbac_limit_deceleration:set_default_value(50);

local mct_section_ai = mct_mod:add_new_section("3-cbac-ai", "AI Behaviour Options [NOT READY]", false);

local option_cbac_upgrade_ai = mct_mod:add_new_option("upgrade_ai_armies", "checkbox");
option_cbac_upgrade_ai:set_text("Enable Upgraded AI Armies");
option_cbac_upgrade_ai:set_tooltip_text("Brings AI armies closer to their army limit if they have the gold to afford it.");
option_cbac_upgrade_ai:set_default_value(false);

local option_cbac_upgrade_grace_period = mct_mod:add_new_option("upgrade_grace_period", "slider");
option_cbac_upgrade_grace_period:set_text("Upgrade Grace Period");
option_cbac_upgrade_grace_period:set_tooltip_text("AI will not upgrade their armies before this turn number.");
option_cbac_upgrade_grace_period:slider_set_min_max(5, 100);
option_cbac_upgrade_grace_period:slider_set_step_size(5);
option_cbac_upgrade_grace_period:set_default_value(20);

local option_cbac_autolevel_ai = mct_mod:add_new_option("auto_level_ai_lords", "slider");
option_cbac_autolevel_ai:set_text("Auto-level AI lords");
option_cbac_autolevel_ai:set_tooltip_text("AI lords will have a minimum level based on the turn number. 0=off 1=slower increase 5=faster increase");
option_cbac_autolevel_ai:slider_set_min_max(0, 5);
option_cbac_autolevel_ai:slider_set_step_size(1);
option_cbac_autolevel_ai:set_default_value(3);

local mct_section_sl = mct_mod:add_new_section("4-cbac-sl", "Cost-based Supply Lines Options", false);

local option_cbac_supply_lines = mct_mod:add_new_option("supply_lines", "checkbox");
option_cbac_supply_lines:set_text("Enable Cost-based Supply Lines");
option_cbac_supply_lines:set_tooltip_text("Adds Supply Lines unit upkeep increases based on army cost. Use the submod to disable the normal Supply Lines!");
option_cbac_supply_lines:set_default_value(false);
