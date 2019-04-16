local singleplayer = minetest.is_singleplayer()
local scripts_dir = minetest.get_worldpath() .. "/formspec_designer/"

-- Player states enum
local fd_MENU   = 0
local fd_LOAD   = 1
local fd_DELETE = 2
local fd_SAVE   = 3
local fd_EDITOR = 4

-- Player table - stores each player's
-- * c_state : the page they are being shown
-- * p_state : the page they were being shown; tracked to implement back button
-- * script  : contents of editor text-area
local players = {}

-- List of players' saved scripts
local scripts = {}

local function get_state(name)
	return players[name].c_state, players[name].p_state
end

-- Update p_state to store the old c_state, and set c_state to new_state
local function update_state(name, new_state)
	players[name].p_state = players[name].c_state
	players[name].c_state = new_state
end

-- Parse user's directory
local function parse_scripts(name)
	scripts[name] = minetest.get_dir_list(scripts_dir .. name .. "/", false)
	local list = scripts[name]
	local log_msg = (list and #list > 0) and dump(list) or "None found"
	minetest.log("info", "[formspec_designer] Parsing scripts of " .. name ..
			": " .. log_msg)
end

-- Main menu
local function show_menu(name)
	update_state(name, fd_MENU)
	minetest.show_formspec(name, "formspec_designer:menu", [[
		size[4,4]
		label[0,0;Formspec Designer]
		button[0,1;4,1;btn_menu_new;New formspec]
		button[0,2;4,1;btn_menu_load;Load formspec]
		button[0,3;4,1;btn_menu_delete;Delete formspec]
	]])
end

-- Load dialog
local function show_load_dlg(name)
	update_state(name, fd_LOAD)
	local list = scripts[name]
	local fs = [[
		size[4,5]
		button[0,4;2,1;btn_dlg_back;Back]
	]]

	if list and #list > 0 then
		fs = fs .. "textlist[0,0;3.8,4;scripts_list;" ..
				table.concat(list, ",") .. "]" ..
				"button[2,4;2,1;btn_dlg_load;Load]"
	else
		fs = fs .. "label[0,2;No saved scripts found!]"
	end

	minetest.show_formspec(name, "formspec_designer:dlg_load", fs)
end

-- Save dialog
local function show_save_dlg(name)
	update_state(name, fd_SAVE)

	local list = scripts[name]
	local fs = [[
		size[4,6]
		field[0,4;4,1;field_dlg_save;;]
		button[0,5;2,1;btn_dlg_back;Back]
		button[2,5;2,1;btn_dlg_save;Save]
	]]

	if list and #list > 0 then
		fs = fs .. "textlist[0,0;3.8,4;scripts_list;" ..
				table.concat(list, ",") .. "]"
	else
		fs = fs .. "label[0,2;No saved scripts found!]"
	end

	minetest.show_formspec(name, "formspec_designer:dlg_save", fs)
end

-- Delete dialog
local function show_delete_dlg(name)
	update_state(name, fd_DELETE)
	local list = scripts[name]
	local fs = [[
		size[4,5]
		button[0,4;2,1;btn_dlg_back;Back]
	]]

	if list and #list > 0 then
		fs = fs .. "textlist[0,0;3.8,4;scripts_list;" ..
				table.concat(list, ",") .. "]" ..
				"button[2,4;2,1;btn_dlg_delete;Delete]"
	else
		fs = fs .. "label[0,2;No saved scripts found!]"
	end

	minetest.show_formspec(name, "formspec_designer:dlg_delete", fs)
end

-- Editor window
local function show_editor(name)
	minetest.chat_send_player(name, "show_editor")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not player then
		return
	end
	local name = player:get_player_name()

	if formname == "formspec_designer:menu" then
		if fields.btn_menu_new then
			show_editor(name)
		elseif fields.btn_menu_load then
			show_load_dlg(name)
		elseif fields.btn_menu_delete then
			show_delete_dlg(name)
		end
	end

	if formname == "formspec_designer:dlg_load" or
			formname == "formspec_designer:dlg_save" or
			formname == "formspec_designer:dlg_delete" then
		if fields.btn_dlg_back then
			-- Get previous state
			local _, state = get_state(name)
			if state == fd_MENU then
				show_menu(name)
			elseif state == fd_EDITOR then
				show_editor(name)
			end
		end
	end
end)

minetest.register_chatcommand("fd", {
	func = function(name)
		if not singleplayer and minetest.check_player_privs(name).server then
			return false, "Insufficient privileges! You need to either use" ..
					" this mod in singleplayer, or have the server priv."
		end

		if not minetest.get_player_by_name(name) then
			return false, "You must be online to open the formspec designer!"
		end

		minetest.log("action", "[formspec_designer] Player " .. name ..
				" opens formspec designer.")

		if not players[name] then
			players[name] = { c_state = fd_MENU }
		end

		if not scripts[name] then
			parse_scripts(name)
		end

		local state = get_state(name)
		if state == fd_MENU then
			show_menu(name)
		elseif state == fd_LOAD then
			show_load_dlg(name)
		elseif state == fd_DELETE then
			show_delete_dlg(name)
		elseif state == fd_SAVE and players[name].script then
			show_save_dlg(name)
		elseif state == fd_EDITOR then
			show_editor(name)
		else
			minetest.log("warning", "[formspec_designer] Invalid player" ..
					" state (" .. state .. ") for " .. name .. "!")

			if players[name].script then
				show_editor(name)
			else
				show_menu(name)
			end
		end
	end
})
