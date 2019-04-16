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

local function get_state(name)
	return players[name].c_state, players[name].p_state
end

local function update_state(name, new_state)
	players[name].p_state = players[name].c_state
	players[name].c_state = new_state
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

-- Scripts list
local function get_scripts_list(name)
	return "textlist[0,0;4,4;scripts_list;" ..
			table.concat(minetest.get_dir_list(
					scripts_dir .. name .. "/", false), ",") ..
			"]"
end

local function show_load_dlg(name)
	update_state(name, fd_LOAD)
	minetest.show_formspec(name, "formspec_designer:dlg_load", "size[4,5]" ..
			"container[0,0]" ..
			get_scripts_list(name) ..
			"container_end[]" ..
			"button[0,4;2,1;btn_dlg_back;Back]" ..
			"button[2,4;2,1;btn_dlg_load;Load]")
end

local function show_save_dlg(name)
	update_state(name, fd_SAVE)
	minetest.show_formspec(name, "formspec_designer:dlg_save", "size[4,6]" ..
			"container[0,0]" ..
			get_scripts_list(name) ..
			"container_end[]" ..
			"field[0,4;4,1;field_dlg_save;;]" ..
			"button[0,5;2,1;btn_dlg_back;Back]" ..
			"button[2,5;2,1;btn_dlg_save;Save]")
end

local function show_delete_dlg(name)
	update_state(name, fd_DELETE)
	minetest.show_formspec(name, "formspec_designer:dlg_delete", "size[4,5]" ..
			"container[0,0]" ..
			get_scripts_list(name) ..
			"container_end[]" ..
			"button[0,4;2,1;btn_dlg_back;Back]" ..
			"button[2,4;2,1;btn_dlg_delete;Delete]")
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
