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
	-- TODO
end

-- Editor window
local function show_editor(name)
	-- TODO
end

minetest.register_chatcommand("fd", {
	func = function(name)
		if not singleplayer and minetest.check_player_privs(name).server then
			return false, "Insufficient privileges! You need to either use" ..
					" this mod in singleplayer, or have the server priv."
		end

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
			minetest.log("warning", "formspec_designer: Corrupted player state (" ..
					player.state .. ") for " .. name .. "!")

			if player.script then
				show_editor(name)
			else
				show_menu(name)
			end
		end
	end
})
