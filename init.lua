local singleplayer = minetest.is_singleplayer()

-- Player states enum
local fd_MENU   = 0
local fd_LOAD   = 1
local fd_DELETE = 2
local fd_SAVE   = 3
local fd_EDITOR = 4

-- Player table - stores each player's
-- * state : the page they are being shown
-- * script: contents of editor text-area, if state == fd_EDITOR
local players = {}

-- Main menu
local function show_menu(name)
	players[name].state = fd_MENU
	minetest.show_formspec(name, "formspec_designer:menu", [[
		size[4,4]
		label[0,0;Formspec Designer]
		button[0,1;4,1;btn_menu_new;New formspec]
		button[0,2;4,1;btn_menu_load;Load formspec]
		button[0,3;4,1;btn_menu_delete;Delete formspec]
	]])
end

-- Load/save/delete dialogs
local function show_scripts_list(name)
	minetest.chat_send_player(name, "show_scripts_list")
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
		elseif fields.btn_menu_load or fields.btn_menu_delete then
			show_scripts_list(name)
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

		local player = players[name]
		if not player then
			players[name] = { state = fd_MENU }
			player = players[name]
		end

		if player.state == fd_MENU then
			show_menu(name)
		elseif player.state == fd_LOAD or
				player.state == fd_DELETE or
				player.state == fd_SAVE then
			show_scripts_list(name)
		elseif player.state == fd_EDITOR then
			show_editor(name)
		else
			minetest.log("warning", "[formspec_designer] Corrupted player" ..
					" state (" .. player.state .. ") for " .. name .. "!")

			if player.script then
				show_editor(name)
			else
				show_menu(name)
			end
		end
	end
})
