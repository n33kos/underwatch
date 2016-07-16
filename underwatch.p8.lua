pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--underwatch v1.0
--author: n33kos

--globals-------------------------------------
----------------------------------------------
ai_entities = {}
player_entity = {}
projectiles = {}
all_entities = {}

drag = {1.05,1.05}
bounce = {0.9,0.9}
gravity = {0,-0.30}
time = 0

cam = {}
cam.pos = {x = 64, y = 128}
cam.offset = {x = 64, y = 64}
cam.followdistance = {x = 1, y = 1}

game = {
	currmap = {},
	firstload = true,
	state = "title",
	menuselection = 0,
	selectedcharacter = 0,
	selectedmap = 0,
	ispaused = false,
	musicchange = true,
	currsong = 4,
	kills = {
		team1 = 0,
		team2 = 0,
	},
	globalfirerate = 1,
	globalgamespeed = 1,
	globalgravity = 1,
	maxfirerate = 3,
	respawncounter = 0,
	respawntime = 5*30,
	objective = {
		team1capturepercentage = 0,
		team2capturepercentage = 0,
		team1controlpercentage = 0,
		team2controlpercentage = 0,
		capturespeed = 0.5,
		controlspeed = 0.2,
		team1_on_point = {},
		team2_on_point = {}
	}
}

--creation functions-----------------------------------
---------------------------------------------------
function make_player()
	player_entity = copy(all_characters[flr(game.selectedcharacter%#all_characters)+1])
	player_entity.isplayer = true
	player_entity.team = "team1"
	for key,val in pairs(player_entity.primary) do
		val.parent = "team1"
		val.firedelay *= game.maxfirerate - game.globalfirerate
	end
	for key,val in pairs(player_entity.alternate) do
		val.parent = "team1"
		val.firedelay *= game.maxfirerate - game.globalfirerate
	end
	spawn = find_spawn_point(player_entity)
	player_entity.pos.x = spawn[1]
	player_entity.pos.y = spawn[2]
end

function make_ai()
	for i=1,11 do
		temp_entity = copy(all_characters[flr(rnd(#all_characters))+1])
		if i < 6 then 
			temp_team = "team1" 
			while temp_entity.character == player_entity.character do
				temp_entity = copy(all_characters[flr(rnd(#all_characters))+1])
			end
		else 
			temp_team = "team2"
		end

		temp_entity.team = temp_team
		for key,val in pairs(temp_entity.primary) do
			val.parent = temp_team
			val.firedelay *= game.maxfirerate - game.globalfirerate
		end
		for key,val in pairs(temp_entity.alternate) do
			val.parent = temp_team
			val.firedelay *= game.maxfirerate - game.globalfirerate
		end
		spawn = find_spawn_point(temp_entity)
		temp_entity.pos.x = spawn[1]
		temp_entity.pos.y = spawn[2]
		add(ai_entities, temp_entity)
	end
end

function make_projectile(entity, projectile)
	temp_proj = copy(projectile)
	temp_proj.pos = {}
	temp_proj.age = 0
	temp_proj.spriteflip = {}
	if entity.spriteflip.x == true then
		temp_proj.spriteflip.x = true
		temp_proj.velocity.x = temp_proj.velocity.x*-1
		temp_proj.pos.x = entity.pos.x-temp_proj.sca.x-temp_proj.pixeloffset.x
	else
		temp_proj.pos.x = entity.pos.x+entity.sca.x+temp_proj.pixeloffset.x
	end
	temp_proj.pos.y = entity.pos.y+temp_proj.pixeloffset.y

	if temp_proj.pos.x > cam.pos.x and temp_proj.pos.x < cam.pos.x+128 and (entity.isplayer or projectile == splat) then
		sfx(temp_proj.sfx, -1)
	end
	add(projectiles, temp_proj)
end

function find_spawn_point(entity)
	points = {}
	for i=0,game.currmap.dim.x do
		for j=0,game.currmap.dim.y do
			val = {i*8,j*8}
			cell = mget(val[1]/8+game.currmap.cel.x,val[2]/8+game.currmap.cel.y)
			if entity.team == "team1" then
				if fget(cell, 4) then
					add(points, val)
				end
			else
				if fget(cell, 5) then
					add(points, val)
				end
			end
		end
	end
	return points[flr(rnd(#points))+1]
end

--ai functions-------------------------------------
---------------------------------------------------
function ai_movement_behavior(entity)
	if entity.pos.x < 192+rnd(10) then
		entity.velocity.x += rnd(entity.speed)+rnd(entity.speed)
	elseif entity.pos.x > 312-rnd(10) then
		entity.velocity.x -= rnd(entity.speed)+rnd(entity.speed)
	else
		if type(entity.target) == "table" and entity.target.isalive then
			if entity.target.pos.x > entity.pos.x+rnd(8) then
				entity.velocity.x += rnd(entity.speed)
			else
				entity.velocity.x -= rnd(entity.speed)
			end
			if entity.isjumping != true and ((entity.velocity.x < 0.15 and entity.velocity.x > -0.15 and entity.velocity.y < 0.15 and entity.velocity.y > -0.15) or entity.pos.y > entity.target.pos.y) then
				entity.velocity.y -= rnd(entity.jumpheight)
			end
		else
			entity.target = ai_get_target(entity)
		end
	end
	if entity.canfly and rnd(10) < 5 then
		entity.velocity.y += gravity[2]*game.globalgravity*entity.mass*2
	else
		if entity.isjumping != true and (rnd(10) < 0.1 or (entity.velocity.x < 0.1 and entity.velocity.x > -0.1)) then
			entity.velocity.y -= rnd(entity.jumpheight)
		end
	end
	entity.current_animation = "walk"

	if entity.velocity.x > 0 then
		entity.spriteflip.x = false
	elseif entity.velocity.x < 0 then
		entity.spriteflip.x = true
	end
end

function ai_attack_behavior(entity)
	--counter
	entity.shottimer -= 1
	entity.alternateshottimer -= 1
	if rnd(10) < 5 then
		if entity.shottimer <= 0 and time%2 == 0 and entity.shields <= 0then
			for key,val in pairs(entity.primary) do
				entity.shottimer = val.firedelay
				make_projectile(entity, val)
			end
		elseif (entity.alternateshottimer <= 0 and time%2 == 1) or entity.shields > 0 then
			for key,val in pairs(entity.alternate) do
				entity.alternateshottimer = val.firedelay
				if (entity.character == "robogirl" and entity.shields > 0) or entity.character != "robogirl" then
					make_projectile(entity, val)
				end
			end
			if entity.character == "rainhorse" or entity.character == "robogirl"  and entity.shields > 0 then
				entity.shielded = true
			end
			if entity.character == "harvester" then
				if entity.spriteflip.x then
					entity.pos.x -= 64
				else
					entity.pos.x += 64
				end
			end
		end
	end
end

function ai_get_target(entity)
	targetteam = {}
	for key,otherentity in pairs(all_entities) do
		if entity.class == "support" then
			if otherentity.team == entity.team then
				add(targetteam, otherentity)
			end
		else
			if otherentity.team != entity.team then
				add(targetteam, otherentity)
			end
		end
	end
	closest_target = nil
	for key,val in pairs(targetteam) do
		if entity.class == "support" then
			if closest_target == nil or (val.hp < closest_target.hp) and closest_target.class != "support" then
				closest_target = val
			end
		else
			if closest_target == nil or (abs(closest_target.pos.x - entity.pos.x) + abs(closest_target.pos.y - entity.pos.y)) > (abs(val.pos.x - entity.pos.x) + abs(val.pos.y - entity.pos.y)) then
				closest_target = val
			end
		end
	end
	return targetteam[flr(rnd(#targetteam))+1]
end

--phys functions-----------------------------------
------------------------------------------------------
function apply_gravity(entity)
	entity.velocity.y = entity.velocity.y-gravity[2]*game.globalgravity*entity.mass
end

function apply_velocity(entity)
	entity.pos.x = entity.pos.x+entity.velocity.x
	entity.pos.y = entity.pos.y+entity.velocity.y
end

function apply_drag(entity)
	entity.velocity.x /= drag[1]
	entity.velocity.y /= drag[2]
end

function apply_entity_map_collision(entity)
	top = {flr((entity.pos.x+(entity.sca.x/2))/8), flr(entity.pos.y/8)}
	bottom = {top[1], flr((entity.pos.y+(entity.sca.y-1))/8)}
	left = {flr(entity.pos.x/8), flr((entity.pos.y+(entity.sca.y/2))/8)}
	right = {flr((entity.pos.x+(entity.sca.x-1))/8), left[2]}
	
	--bottom
	val = mget(bottom[1]+game.currmap.cel.x, bottom[2]+game.currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.y /= 4
		entity.mass = 0
		entity.isjumping = false
		entity.pos.y = flr((bottom[2]-1)*8) -- make sure the entity stays within bounds
		return
	else
		entity.isjumping = true
		entity.mass = 1
	end

	--top
	val = mget(top[1]+game.currmap.cel.x, top[2]+game.currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.y *= -bounce[2]/4
		entity.pos.y = flr((top[2]+1)*8) -- make sure the entity stays within bounds
	end

	--left
	val = mget(left[1]+game.currmap.cel.x, left[2]+game.currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= -bounce[1]/4
		entity.pos.x = flr((left[1]+1)*8) -- make sure the entity stays within bounds
	end

	--right
	val = mget(right[1]+game.currmap.cel.x, right[2]+game.currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= -bounce[1]/4
		entity.pos.x = flr((right[1]-1)*8) -- make sure the entity stays within bounds
	end
end

function apply_projectile_map_collision(bullet)
	if bullet.bounce then
		top = {flr((bullet.pos.x+(bullet.sca.x/2))/8), flr(bullet.pos.y/8)}
		bottom = {top[1], flr((bullet.pos.y+bullet.sca.y)/8)}
		left = {flr(bullet.pos.x/8), flr((bullet.pos.y+(bullet.sca.y/2))/8)}
		right = {flr((bullet.pos.x+(bullet.sca.x))/8), left[2]}
		
		--bottom
		val = mget(bottom[1]+game.currmap.cel.x, bottom[2]+game.currmap.cel.y)
		if fget(val, 7) == true then
			bullet.velocity.y *= -bounce[2]
			bullet.pos.y = (bottom[2]-1)*8 -- make sure the bullet stays within bounds
			return
		end

		--left
		val = mget(left[1]+game.currmap.cel.x, left[2]+game.currmap.cel.y)
		if fget(val, 7) == true then
			bullet.velocity.x *= -bounce[1]
			bullet.pos.x = (left[1]+1)*8 -- make sure the bullet stays within bounds
			return
		end

		--right
		val = mget(right[1]+game.currmap.cel.x, right[2]+game.currmap.cel.y)
		if fget(val, 7) == true then
			bullet.velocity.x *= -bounce[1]
			bullet.pos.x = (right[1]-1)*8 -- make sure the bullet stays within bounds
			return
		end

		--top
		val = mget(top[1]+game.currmap.cel.x, top[2]+game.currmap.cel.y)
		if fget(val, 7) == true then
			bullet.velocity.y *= -bounce[2]
			bullet.pos.y = (top[2]+1)*8 -- make sure the bullet stays within bounds
			return
		end
	else
		val = mget(flr(bullet.pos.x/8)+game.currmap.cel.x, flr(bullet.pos.y/8)+game.currmap.cel.y)
		if fget(val, 7) == true then
			if bullet.explode then
				for i=0,1 do
					explosion.parent = bullet.parent
					make_projectile(bullet, explosion)
				end
			end
			del(projectiles, bullet)
			return
		end
	end
end

function apply_ladder_collision(entity)
	val = mget(flr((entity.pos.x+entity.sca.x/2)/8)+game.currmap.cel.x, flr((entity.pos.y)/8)+game.currmap.cel.y)
	if fget(val, 6) == true then
		entity.onladder = true
		entity.isjumping = false
		entity.velocity.y = -gravity[2]/2
	else
		entity.onladder = false
	end
end

function apply_projectile_entity_collision(entity)
	for key,bullet in pairs(projectiles) do
		c = bullet.pos.x;
		d = bullet.pos.y;
		a = c+bullet.sca.x;
		b = d+bullet.sca.y;

		y = entity.pos.x;
		z = entity.pos.y;
		w = y+entity.sca.x;
		x = z+entity.sca.y;

		intersect = true
		if(a<w and c<w and a<y and c<y) intersect = false
		if(a>w and c>w and a>y and c>y) intersect = false
		if(b<x and d<x and b<z and d<z) intersect = false
		if(b>x and d>x and b>z and d>z) intersect = false
		if intersect and 
		bullet.damage != 0 and
		--bullet.damage != nil and 
		((bullet.damage > 0 and bullet.parent != entity.team) or 
		(bullet.damage < 0 and bullet.parent == entity.team)) then
			--damage
			if entity.shielded and entity.shields > 0 and bullet.damage > 0 then
				entity.shields -= bullet.damage
			else
				entity.hp = min(entity.hp-bullet.damage, entity.maxhp)
			end

			--explode
			if bullet.explode then
				for i=0,1 do
					explosion.parent = bullet.parent
					make_projectile(bullet, explosion)
				end
			end

			--destroy projectile
			if bullet.damage > 0 then
				del(projectiles, bullet)
			elseif bullet.damage < 0 then
				entity.ishealing = true
			end

		end

		--knockback
		if intersect and bullet.knockback and bullet.parent != entity.team then
			entity.velocity.x += bullet.velocity.x/4
			entity.velocity.y += bullet.velocity.y/4
		end
	end
end

--drawing functions-----------------------------------
------------------------------------------------------
function draw_entity(entity)
	spr(entity.sprite, entity.pos.x, entity.pos.y, entity.sca.x/8, entity.sca.y/8, entity.spriteflip.x, entity.spriteflip.y)
end

function draw_map()
	map(game.currmap.cel.x, game.currmap.cel.y, 0, 0, game.currmap.dim.x, game.currmap.dim.y)
end

function parallax_bg()
	srand(3.14159)
	for i=0,256 do
		x = flr(rnd(game.currmap.dim.x*8)-cam.pos.x/8)
		y = flr(rnd(game.currmap.dim.y*8))
		line(x, y, x+rnd(15), y, game.currmap.bgcolor)
	end
	srand(time)
end

function move_camera()
	if player_entity.isalive then
		cam.target = player_entity
	else
		cam.target = ai_entities[1]
	end
	if cam.target then
		cam.pos.x = min(max(cam.pos.x + (cam.target.pos.x - (cam.pos.x+cam.offset.x))/cam.followdistance.x, 0), game.currmap.dim.x*8-128)
		cam.pos.y = min(max(cam.pos.y + (cam.target.pos.y - (cam.pos.y+cam.offset.y))/cam.followdistance.y, 0), game.currmap.dim.y*8-128)
	end
	camera(cam.pos.x,cam.pos.y)
end

function set_animation_frame(entity)
	--select animation based on movement
	if entity.isjumping and entity.velocity.y < 0 then
		entity.current_animation = "jump"
	elseif entity.velocity.x > 0.2 or entity.velocity.x < -0.2 then
		entity.current_animation = "walk"
	else
		entity.current_animation = "idle"
	end

	--assign animation frame to draw sprite. animation frames use time modulus the length of the animation
	anim = entity.animations[entity.current_animation]
	entity.sprite = anim[time % #anim+1]
end

function projectile_anim(entity)
	if type(entity.animation) == "table" and #entity.animation > 0 then
		entity.sprite = entity.animation[time % #entity.animation+1]
	end
end

function draw_health_bar(entity)
	if entity.team == "team1" then
		colors = {1,12}
	else
		colors = {2,8}
	end
	line(entity.pos.x, entity.pos.y-7, entity.pos.x+entity.sca.x, entity.pos.y-7, colors[1])
	line(entity.pos.x, entity.pos.y-7, entity.pos.x+((entity.hp/entity.maxhp)*entity.sca.x), entity.pos.y-7, colors[2])
	if entity.shields > 0 then
		line(entity.pos.x, entity.pos.y-8, entity.pos.x+((entity.shields/entity.maxshields)*entity.sca.x), entity.pos.y-8, 9)
	end
end

function draw_objective_rect()
	--capture indicator
	rectfill(cam.pos.x+59+flr((100 - game.objective.team1capturepercentage)/20), cam.pos.y, cam.pos.x+64, cam.pos.y+6, 7)
	rectfill(cam.pos.x+64, cam.pos.y, cam.pos.x+64+flr(game.objective.team2capturepercentage/20),cam.pos.y+6, 7)

	--control bg
	rectfill(cam.pos.x+29, cam.pos.y, cam.pos.x+59, cam.pos.y+6, 1)
	rectfill(cam.pos.x+69, cam.pos.y, cam.pos.x+99, cam.pos.y+6, 2)

	--control indicator
	rectfill(cam.pos.x+29+flr((100 - game.objective.team1controlpercentage)/3.3333), cam.pos.y, cam.pos.x+59, cam.pos.y+6, 12)
	rectfill(cam.pos.x+69, cam.pos.y, cam.pos.x+69+flr(game.objective.team2controlpercentage/3.3333), cam.pos.y+6, 8)

	--gui
	print(flr(game.objective.team1controlpercentage).."%", cam.pos.x+44, cam.pos.y+1, 0)
	print(flr(game.objective.team2controlpercentage).."%", cam.pos.x+80, cam.pos.y+1, 0)
end

function draw_kills()
	spr(105, cam.pos.x, cam.pos.y)
	spr(104, cam.pos.x+120, cam.pos.y)
	print(game.kills.team1, cam.pos.x+9, cam.pos.y+2, 12)
	print(game.kills.team2, cam.pos.x+120-flr(#(game.kills.team2.."")*4), cam.pos.y+2, 8)
end

function draw_main_menu_screen()
	--window
	rectfill(cam.pos.x+8, cam.pos.y+8, cam.pos.x+120, cam.pos.y+120, 0)
	rect(cam.pos.x+6, cam.pos.y+6, cam.pos.x+122, cam.pos.y+122, 1)
	rect(cam.pos.x+8, cam.pos.y+8, cam.pos.x+120, cam.pos.y+120, 12)

	--logo
	sspr(0, 48, 56, 8, cam.pos.x+15, cam.pos.y+15, 100, 12)

	print("press z or x to play", cam.pos.x+26	, cam.pos.y+27, 6)

	--settings
	selectedchar = all_characters[flr(game.selectedcharacter%#all_characters)+1]

	--char preview
	sspr(flr(selectedchar.animations.walk[time%#selectedchar.animations.walk+1]%16)*8, flr(selectedchar.animations.walk[time%#selectedchar.animations.walk+1]/16)*8, 8, 8, cam.pos.x+20, cam.pos.y+50, 16, 16)
	if game.menuselection == 0 then drcol = 12 else drcol = 1 end
	print(selectedchar.class, cam.pos.x+46, cam.pos.y+50, drcol)
	print("z - "..selectedchar.primarydesc, cam.pos.x+46, cam.pos.y+56, drcol)
	print("x - "..selectedchar.alternatedesc, cam.pos.x+46, cam.pos.y+62, drcol)
	if selectedchar.character == "sk8rboi" then
		print("passive area heal", cam.pos.x+46, cam.pos.y+68, drcol)
	end
	if selectedchar.character == "farout" then
		print("up - flight", cam.pos.x+46, cam.pos.y+68, drcol)
	end

	menu = {
		"character: "..selectedchar.character,
		"map: "..all_maps[flr(game.selectedmap%#all_maps)+1].name,
		"capture speed: "..game.globalgamespeed.."x",
		"gravity: "..game.globalgravity.."x",
		"fire rate: "..game.globalfirerate.."x",
	}

	for i=0,4 do
		if i == 0 then spacer = 40 else spacer = 68 end
		if game.menuselection == i then
			print(menu[i+1], cam.pos.x+20, cam.pos.y+spacer+(i*10), 12)
		else
			print(menu[i+1], cam.pos.x+20, cam.pos.y+spacer+(i*10), 1)
		end
	end

	--controls
	if btnp(2) then
		game.menuselection = max(0,game.menuselection-1)
		sfx(0)
	end
	if btnp(3) then
		game.menuselection = min(#menu-1,game.menuselection+1)
		sfx(0)
	end
	if btnp(0) then
		if game.menuselection == 0 then
			game.selectedcharacter += 1
		elseif game.menuselection == 1 then
			game.selectedmap += 1
		elseif game.menuselection == 2 then
			game.globalgamespeed = max(0.1, game.globalgamespeed-0.1)
		elseif game.menuselection == 3 then
			game.globalgravity = max(0.1, game.globalgravity-0.1)
		elseif game.menuselection == 4 then
			game.globalfirerate = max(0.1, game.globalfirerate-0.1)
		end
		sfx(0)
	end
	if btnp(1) then
		if game.menuselection == 0 then
			game.selectedcharacter -= 1
		elseif game.menuselection == 1 then
			game.selectedmap -= 1
		elseif game.menuselection == 2 then
			game.globalgamespeed = min(5, game.globalgamespeed+0.1)
		elseif game.menuselection == 3 then
			game.globalgravity += 0.1
		elseif game.menuselection == 4 then
			game.globalfirerate = min(game.maxfirerate, game.globalfirerate+0.1)
		end
		sfx(0)
	end
	if (btnp(4) and btnp(5) == false) or (btnp(5) and btnp(4) == false) then
		game.state = "play"
		game.currsong = 15
		game.musicchange = true
	end

	game.currmap = all_maps[flr(game.selectedmap%#all_maps)+1]
end

function draw_title_screen()
	cls()
	parallax_bg()
	rectfill(cam.pos.x+8, cam.pos.y+28, cam.pos.x+120, cam.pos.y+84, 0)
	rect(cam.pos.x+6, cam.pos.y+26, cam.pos.x+122, cam.pos.y+86, 1)
	rect(cam.pos.x+8, cam.pos.y+28, cam.pos.x+120, cam.pos.y+84, 12)

	--logo
	sspr(56, 48, 8, 8, cam.pos.x+54, cam.pos.y+40, 16, 16)
	sspr(0, 48, 56, 8, cam.pos.x+15, cam.pos.y+60, 100, 12)

	print("press any key", cam.pos.x+36, cam.pos.y+90, 12)

	if btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) then
		game.state = "menu"
	end
end

function draw_play_screen()
	game.ispaused = false

	if game.firstload then
		game.firstload = false
		time = 0
		ai_entities = {}
		player_entity = {}
		game.kills.team1 = 0
		game.kills.team2 = 0
		game.objective.team1capturepercentage = 0
		game.objective.team2capturepercentage = 0
		game.objective.team1controlpercentage = 0
		game.objective.team2controlpercentage = 0
		make_player()
		make_ai()
	elseif player_entity.character != selectedchar.character then
		player_entity = {}
		make_player()
	end

	draw_objective_rect()
	draw_kills()

	--player feedback------------------------------------
	-----------------------------------------------------
	if btn(0) then
		--left
		player_entity.velocity.x -= player_entity.speed
		player_entity.spriteflip.x = true
	end
	if btn(1) then
		--right
		player_entity.velocity.x += player_entity.speed
		player_entity.spriteflip.x = false
	end
	if btn(2) then
		--up
		if player_entity.canfly then
			player_entity.velocity.y += gravity[2]*game.globalgravity*player_entity.mass*2
		elseif player_entity.isjumping == false then
			player_entity.velocity.y -= player_entity.jumpheight
			player_entity.isjumping = true
		end
	end
	if btn(3) then
		--down
		player_entity.onladder = false
		player_entity.isjumping = true
	end
	if btn(4) then
		--primary fire
		if player_entity.shottimer <= 0 then
			for key,val in pairs(player_entity.primary) do
				player_entity.shottimer = val.firedelay
				make_projectile(player_entity, val)
			end
		end
	elseif btn(5) then
		--alternate fire
		if player_entity.alternateshottimer <= 0 then
			for key,val in pairs(player_entity.alternate) do
				player_entity.alternateshottimer = val.firedelay
				make_projectile(player_entity, val)
			end

			if player_entity.character == "rainhorse" or player_entity.character == "robogirl" and player_entity.shields > 0 then
				player_entity.shielded = true
			end

			if player_entity.character == "harvester" then
				if player_entity.spriteflip.x then
					player_entity.pos.x -= 64
				else
					player_entity.pos.x += 64
				end
			end
		end
	end
end

function draw_score_screen()
	if game.firstload == false then
		game.firstload = true
		game.currsong = 8
		game.musicchange = true
		--game.ispaused = true
		kills = {game.kills.team1, game.kills.team2}
		control = {min(flr(game.objective.team1controlpercentage), 100), min(flr(game.objective.team2controlpercentage),100)}
		if control[1] > control[2] then
			sfx(6, 1)
		else
			sfx(5, 1)
		end
	end
	
	--window
	rectfill(cam.pos.x+8, cam.pos.y+12, cam.pos.x+120, cam.pos.y+120, 0)
	rect(cam.pos.x+6, cam.pos.y+10, cam.pos.x+122, cam.pos.y+122, 1)
	rect(cam.pos.x+8, cam.pos.y+12, cam.pos.x+120, cam.pos.y+120, 12)

	--logo
	sspr(0, 48, 56, 8, cam.pos.x+15, cam.pos.y+30, 100, 12)
	
	if control[1] > control[2] then
		print("win", cam.pos.x+60, cam.pos.y+50, 12)
	else
		print("defeat", cam.pos.x+55, cam.pos.y+50, 8)
	end
	
	print("kills: ", cam.pos.x+15, cam.pos.y+70, 6)
	print(kills[1], cam.pos.x+60, cam.pos.y+70, 12)
	print(kills[2], cam.pos.x+90, cam.pos.y+70, 8)

	print("control: ", cam.pos.x+15, cam.pos.y+80, 6)
	print(control[1].."%", cam.pos.x+60, cam.pos.y+80, 12)
	print(control[2].."%", cam.pos.x+90, cam.pos.y+80, 8)

	print("press z+x to restart", cam.pos.x+24, cam.pos.y+110, 1)
	if btnp(4) and btnp(5) then game.state = "title" end
end

function draw_healing_indicator(entity)
	if entity.team == "team1" then
		sspr(44, 56, 4, 3, entity.pos.x+2, entity.pos.y-12, 4 ,3)
	else
		sspr(40, 56, 4, 3, entity.pos.x+2, entity.pos.y-12, 4 ,3)
	end
end

--game functions-----------------------------------
---------------------------------------------------
function assess_capture()
	if game.state == "play" and game.firstload == false then
		game.objective.team1_on_point = {}
		game.objective.team2_on_point = {}
		--is on point count
		for key,entity in pairs(all_entities) do
			val = mget(flr((entity.pos.x+entity.sca.x/2)/8), flr((entity.pos.y+entity.sca.y/2)/8))
			if entity.team == "team1" then
				if fget(val, 3) then
					add(game.objective.team1_on_point, entity)
				else
					del(game.objective.team1_on_point, entity)
				end
			else
				if fget(val, 3) then
					add(game.objective.team2_on_point, entity)
				else
					del(game.objective.team2_on_point, entity)
				end
			end
		end

		--capture logic
		if #game.objective.team1_on_point > 0 and #game.objective.team2_on_point <= 0 then
			game.objective.team1capturepercentage = min(game.objective.team1capturepercentage + game.objective.capturespeed*game.globalgamespeed*#game.objective.team1_on_point, 100)
			game.objective.team2capturepercentage = max(game.objective.team2capturepercentage - game.objective.capturespeed*game.globalgamespeed*#game.objective.team1_on_point, 0)
		elseif #game.objective.team2_on_point > 0 and #game.objective.team1_on_point <= 0 then
			game.objective.team1capturepercentage = max(game.objective.team1capturepercentage - game.objective.capturespeed*game.globalgamespeed*#game.objective.team2_on_point, 0)
			game.objective.team2capturepercentage = min(game.objective.team2capturepercentage + game.objective.capturespeed*game.globalgamespeed*#game.objective.team2_on_point, 100)
		else
			game.objective.team1capturepercentage = max(game.objective.team1capturepercentage - game.objective.capturespeed*game.globalgamespeed, 0)
			game.objective.team2capturepercentage = max(game.objective.team2capturepercentage - game.objective.capturespeed*game.globalgamespeed, 0)
		end

		--control logic
		if game.objective.team1capturepercentage >= 100 then
			game.objective.team1controlpercentage += game.objective.controlspeed*game.globalgamespeed*#game.objective.team1_on_point
		elseif game.objective.team2capturepercentage >= 100 then
			game.objective.team2controlpercentage += game.objective.controlspeed*game.globalgamespeed*#game.objective.team2_on_point
		end

		--win logic
		if game.objective.team1controlpercentage >= 100 or game.objective.team2controlpercentage >= 100 then
			game.state = "score"
		end
	end
end

function ai_update_loop()
	for key,entity in pairs(ai_entities) do
		if entity.hp > 0 then
			ai_movement_behavior(entity)
			ai_attack_behavior(entity)
		else
			if entity.isalive then
				if entity.team == "team1" then
					game.kills.team2 += 1
				else
					game.kills.team1 += 1
				end
				entity.isalive = false
				temp_proj = copy(splat)
				make_projectile(entity,temp_proj)
			end
		end
	end
end

function ai_draw_loop()
	for key,entity in pairs(ai_entities) do
		--respawn
		if entity.hp <= 0 then
			entity.respawncounter += 1

			if entity.respawncounter >= game.respawntime then
				respawncounter = 0
				team = entity.team
				tmp = {}
				for k,v in pairs(all_characters) do
					if v.character == entity.character then tmp = copy(v) end
				end
				tmp.team = team
				spawn = find_spawn_point(tmp)
				tmp.pos.x = spawn[1]
				tmp.pos.y = spawn[2]
				for key,projectile in pairs(tmp.primary) do
					projectile.parent = team
					projectile.firedelay *= game.maxfirerate - game.globalfirerate
				end
				for key,projectile in pairs(tmp.alternate) do
					projectile.parent = team
					projectile.firedelay *= game.maxfirerate - game.globalfirerate
				end
				add(ai_entities, tmp)
				del(ai_entities, entity)
			end
		else
			--draw
			if entity.pos.x > cam.pos.x and entity.pos.x < cam.pos.x+128 then
				draw_entity(entity)
				draw_health_bar(entity)
			end
		end
	end
end

function player_update_loop()
	if player_entity.hp > 0 then
		player_entity.shottimer -= 1
		player_entity.alternateshottimer -= 1
	else
		if player_entity.isalive then
			if player_entity.team == "team1" then
				game.kills.team2 += 1
			else
				game.kills.team1 += 1
			end
			temp_proj = copy(splat)
			make_projectile(player_entity,temp_proj)
			player_entity.isalive = false
		end
	end
end

function player_draw_loop()
	--draw
	if player_entity.hp > 0 then
		draw_entity(player_entity)
		draw_health_bar(player_entity)
	end

	--resets
	if player_entity.character == "rainhorse" or player_entity.character == "robogirl" then
		player_entity.shielded = false
	end

	--player respawn counter
	if player_entity.isalive == false then
		game.respawncounter += 1

		rectfill(cam.pos.x+58, cam.pos.y+50, cam.pos.x+69, cam.pos.y+62, 0)
		sspr(flr(104%16)*8, flr(104/16)*8, 8, 8, cam.pos.x+56, cam.pos.y+50, 16, 16)
		print(flr((game.respawntime-game.respawncounter)/30)+1, cam.pos.x+62, cam.pos.y+60, 7)

		rectfill(cam.pos.x+29, cam.pos.y+109, cam.pos.x+101, cam.pos.y+115, 0)
		print("press z+x for menu", cam.pos.x+30, cam.pos.y+110, 7)

		if btnp(4) and btnp(5) then
			game.state = "menu"
		end
		if game.respawncounter >= game.respawntime then
			game.respawncounter = 0
			make_player()
		end
	end

end

function projectile_update_loop()
	for key,entity in pairs(projectiles) do
		cleanup(entity)
		apply_gravity(entity)
		apply_velocity(entity)
		projectile_anim(entity)
		entity.age += 1
		if entity.age >= entity.maxage then
			if entity.explode then
				make_projectile(entity, explosion)
			end
			del(projectiles, entity)
		end
	end
end

function projectile_draw_loop()
	for key,entity in pairs(projectiles) do
		if entity.pos.x > cam.pos.x and entity.pos.x < cam.pos.x+128 then
			draw_entity(entity)
		end
		apply_projectile_map_collision(entity)
	end
end

function universal_update_loop()
	for key,entity in pairs(all_entities) do
		if entity.hp > 0 then
			entity.ishealing = false
			cleanup(entity)
			if entity.onladder == false then
				apply_gravity(entity)
			end
			apply_velocity(entity)
			apply_drag(entity)
			apply_entity_map_collision(entity)
			apply_ladder_collision(entity)
			apply_projectile_entity_collision(entity)
			set_animation_frame(entity)
			--special
			if entity.character == "sk8rboi" then
				for key,val in pairs(all_entities) do
					if abs(entity.pos.x - val.pos.x) <= 16 and abs(entity.pos.y - val.pos.y) <= 16 and val.team == entity.team and val != entity and val.isalive then
						val.hp = min(val.hp+0.5, val.maxhp)
						val.ishealing = true
					end
				end
			end
		end
	end
end

function universal_draw_loop()
	for key,entity in pairs(all_entities) do
		--special
		if entity.character == "rainhorse" and entity.shielded and entity.shields > 0 then
			if entity.spriteflip.x then
				line(entity.pos.x,entity.pos.y,entity.pos.x,entity.pos.y+entity.sca.y,12)
			else
				line(entity.pos.x+entity.sca.x,entity.pos.y,entity.pos.x+entity.sca.x,entity.pos.y+entity.sca.y,12)
			end
		end
		if entity.ishealing and entity.isalive then
			draw_healing_indicator(entity)
		end
	end
end

--helper functions----------------------------
----------------------------------------------
function copy(o)
	local c
	if type(o) == 'table' then
		c = {}
		for k, v in pairs(o) do
		c[k] = copy(v)
		end
	else
		c = o
	end
	return c
end

function cleanup(entity)
	if entity.pos.x < 0 or entity.pos.x > game.currmap.dim.x*8 or entity.pos.y < 0 or entity.pos.y > game.currmap.dim.y*8 then
		entity.hp = 0
		entity.age = 2047
	end
end

function manage_music()
	if game.musicchange then
		music(game.currsong)
		game.musicchange = false
	end
end

--execution---------------------------------------
--------------------------------------------------
function _init()
	cls()
	game.currmap = all_maps[flr(game.selectedmap%#all_maps)+1]
	make_player()
end

function _update()
	if game.ispaused == false then
		all_entities = {}
		for k,v in pairs(ai_entities) do add(all_entities,v) end
		add(all_entities, player_entity)
		--game objectives
		assess_capture()
		--ai entities
		ai_update_loop()
		--player entities
		player_update_loop()
		--universal update loop
		universal_update_loop()
		--projectiles
		projectile_update_loop()
	end
end

function _draw()
	if game.ispaused == false then
		--clear screen
		cls()
		--increment time
		time += 1 if time > 2047 then time = 0 end
		--camera
		move_camera()
		--map
		parallax_bg()
		draw_map()
		--universal draw loop
		universal_draw_loop()
		--ai entities
		ai_draw_loop()
		--player entities
		player_draw_loop()
		--projectiles
		projectile_draw_loop()
		--music
		manage_music()
	end

	--gui----------------------------------------
	---------------------------------------------
	if game.state == "title" then
		draw_title_screen()
	elseif game.state == "menu" then
		draw_main_menu_screen()
	elseif game.state == "play" then
		draw_play_screen()
	elseif game.state == "score" then
		draw_score_screen()
	end
end


--character definitions----------------------
---------------------------------------------
char_template = {
	pos = {x = 0, y = 0},
	sca = {x = 8, y = 8},
	velocity = {x = rnd(2), y = rnd(2)},
	mass = 1,
	speed = 0.05,
	jumpheight = 5,
	isjumping = true,
	isplayer = false,
	onladder = false,
	isalive = true,
	ishealing = false,
	canfly = false,
	shielded = false,
	hp = 50,
	maxhp = 50,
	shields = 0,
	maxshields = 0,
	sprite = 0,
	team = "none",
	class = "offense",
	current_animation = "idle",
	attack_behavior = "cycle",
	respawncounter = 0,
	spriteflip = {x = true, y = false},
	shottimer = 0,
	primary = {},
	alternateshottimer = 0,
	--alternate = {},
	spriteflip = {x = true,y = false}
}

----------------projectiles-----------------
explosion = {
	sprite = 63,
	sfx = 3,
	mass = 0,
	maxage = 30,
	bounce = true,
	animation = {20,20,20,41,41,41,63,63,63},
	damage = 20,
	firedelay = 0, --draw frames between shots
	velocity = {
		x = 0,
		y = gravity[2],
	},
	sca = {
		x = 8,
		y = 8,
	},
	pixeloffset = {
		x = 0,
		y = 0,
	},
}

splat = {
	sprite = 15,
	sfx = 12,
	mass = 0,
	maxage = 15,
	bounce = true,
	animation = {15,15,15,15,15,31,31,31,31,31,47,47,47,47,47},
	damage = 0,
	firedelay = 0, --draw frames between shots
	velocity = {
		x = 0,
		y =0,
	},
	sca = {
		x = 8,
		y = 8,
	},
	pixeloffset = {
		x = 0,
		y = 0,
	},
}


----------------soldier24-----------------
soldier24 = {}
soldier24 = copy(char_template)
soldier24.character = "soldier24"
soldier24.animations = {
	idle = {0},
	walk = {1,1,1,1,2,2,2,2},
	jump = {1},
}
soldier24.hp = 100
soldier24.maxhp = 100
soldier24.primarydesc = "rifle"
soldier24.primary = {}
	soldier24.primary[1] = {
		sprite = 3,
		sfx = 2,
		mass = 0.1,
		maxage = 10,
		bounce = false,
		damage = 17,
		firedelay = 6,
		velocity = {
			x = 6,
			y = 0,
		},
		sca = {
			x = 2,
			y = 1,
		},
		pixeloffset = {
			x = 0,
			y = 3,
		}
	}
soldier24.alternatedesc = "rocket"
soldier24.alternate = {}
	soldier24.alternate[1] = {
		sprite = 4,
		sfx = 4,
		mass = 0.5,
		maxage = 30,
		bounce = false,
		damage = 75,
		firedelay = 50,
		velocity = {
			x = 5,
			y = -0.5,
		},
		sca = {
			x = 4,
			y = 2,
		},
		pixeloffset = {
			x = 0,
			y = 4,
		},
		explode = true,
	}

---------------filthmouse--------------
filthmouse = {}
filthmouse = copy(char_template)
filthmouse.character = "filthmouse"
filthmouse.class = "defense"
filthmouse.hp = 200
filthmouse.maxhp = 200
filthmouse.animations = {
	idle = {32},
	walk = {33,33,33,34,34,34},
	jump = {33}
}
filthmouse.primarydesc = "grenade"
filthmouse.primary = {}
	filthmouse.primary[1] = {
		parent = "",
		sprite = 35,
		sfx = 4,
		mass = 1,
		maxage = 25,
		bounce = true,
		damage =60,
		firedelay = 25,
		velocity = {x = 4,y = -4},
		sca = {x = 3,y = 3},
		pixeloffset = {x = 0,y = 3},
		explode = true
	}
filthmouse.alternatedesc = "landmine"
filthmouse.alternate = {}
	filthmouse.alternate[1] = {
		parent = "",
		sprite = 36,
		sfx = 4,
		mass = 2,
		maxage = 20,
		bounce = true,
		damage = 120,
		firedelay = 50,
		velocity = {x = 2,y = -1},
		sca = {x = 6,y = 2},
		pixeloffset = {x = 0,y = 3},
		explode = true
	}

------------------rainhorse----------------------
rainhorse = {}
rainhorse = copy(char_template)
rainhorse.character = "rainhorse"
rainhorse.class = "tank"
rainhorse.mass = 1
rainhorse.speed *= 0.75
rainhorse.hp = 300
rainhorse.maxhp = 300
rainhorse.shields = 200
rainhorse.maxshields = 200
rainhorse.animations = {
	idle = {16},
	walk = {17,17,17,18,18,18},
	jump = {17}
}
rainhorse.primarydesc = "hammer"
rainhorse.primary = {}
	rainhorse.primary[1] = {
		parent = "",
		sprite = 19,
		sfx = 3,
		mass = 1,
		maxage = 4,
		bounce = false,
		damage = 75,
		firedelay = 20,
		knockback = true,
		velocity = {x = 2,y = 1},
		sca = {x = 6,y = 6},
		pixeloffset = {x = 0,y = 0}
	}
rainhorse.alternatedesc = "shield"
rainhorse.alternate = {}

--------------------------spiderlady----------------------
spiderlady = {}
spiderlady = copy(char_template)
spiderlady.character = "spiderlady"
spiderlady.class = "defense"
spiderlady.speed *= 1.5
spiderlady.hp = 200
spiderlady.maxhp = 200
spiderlady.animations = {
	idle = {5},
	walk = {6,6,6,7,7,7},
	jump = {6}
}
spiderlady.primarydesc = "sniper rifle"
spiderlady.primary = {}
	spiderlady.primary[1] = {
		parent = "",
		sprite = 8,
		sfx = 9,
		mass = 0.1,
		maxage = 50,
		bounce = false,
		damage = 100,
		firedelay = 20,
		velocity = {x = 8,y = 0},
		sca = {x = 8,y = 1},
		pixeloffset = {x = 0,y = 2}
	}
spiderlady.alternatedesc = "mine"
spiderlady.alternate = {}
	spiderlady.alternate[1] = {
		parent = "",
		sprite = 9,
		sfx = 8,
		mass = 1,
		maxage = 10,
		bounce = true,
		damage = 30,
		firedelay = 60,
		velocity = {x = 5,y = -2.5},
		sca = {x = 4,y = 2},
		pixeloffset = {x = 0,y = 0}
	}

--------------------------grace----------------------
grace = {}
grace = copy(char_template)
grace.character = "grace"
grace.class = "support"
grace.speed *= 1.5
grace.jumpheight = 5
grace.hp = 200
grace.maxhp = 200
grace.mass = 0.01
grace.animations = {
	idle = {21},
	walk = {22,22,22,22,23,23,23,23},
	jump = {22}
}
grace.primarydesc = "heal beam"
grace.primary = {}
	grace.primary[1] = {
		parent = "",
		sprite = 24,
		sfx = 999,
		mass = 0.1,
		maxage = 2,
		bounce = false,
		damage = -2,
		firedelay = 1,
		velocity = {x = 1,y = 0},
		sca = {x = 8,y = 3},
		pixeloffset = {x = 2,y = 1}
	}
grace.alternatedesc = "pistol"
grace.alternate = {}
	grace.alternate[1] = {
		parent = "",
		sprite = 25,
		sfx = 2,
		mass = 0.1,
		maxage = 10,
		bounce = false,
		damage = 20,
		firedelay = 10,
		velocity = {x = 6,y = 0},
		sca = {x = 2,y = 1},
		pixeloffset = {x = 0,y = 2}
	}
		
--------------------------zohan----------------------
zohan = {}
zohan = copy(char_template)
zohan.character = "zohan"
zohan.class = "defense"
zohan.jumpheight = 5
zohan.hp = 200
zohan.maxhp = 200
zohan.mass = 0.1
zohan.animations = {
	idle = {37},
	walk = {38,38,38,38,39,39,39,39},
	jump = {38}
}
zohan.primarydesc = "bow"
zohan.primary = {}
	zohan.primary[1] = {
		parent = "",
		sprite = 40,
		sfx = 10,
		mass = 1,
		maxage = 40,
		bounce = false,
		damage = 80,
		firedelay = 20,
		velocity = {x = 6,y = -2},
		sca = {x = 5,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
zohan.alternatedesc = "multishot"
zohan.alternate = {}
	zohan.alternate[1] = {
		parent = "",
		sprite = 40,
		sfx = 10,
		mass = 1,
		maxage = 40,
		bounce = true,
		damage = 20,
		firedelay = 35,
		velocity = {x = 6,y = -2},
		sca = {x = 5,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
	zohan.alternate[2] = {
		parent = "",
		sprite = 40,
		sfx = 10,
		mass = 1,
		maxage = 40,
		bounce = true,
		damage = 20,
		firedelay = 35,
		velocity = {x = 6,y = -3},
		sca = {x = 5,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
	zohan.alternate[3] = {
		parent = "",
		sprite = 40,
		sfx = 10,
		mass = 1,
		maxage = 40,
		bounce = true,
		damage = 20,
		firedelay = 35,
		velocity = {x = 6,y = -1},
		sca = {x = 5,y = 1},
		pixeloffset = {x = 0,y = 3}
	}

--------------------------harvester----------------------
harvester = {}
harvester = copy(char_template)
harvester.character = "harvester"
harvester.jumpheight = 5
harvester.hp = 250
harvester.maxhp = 250
harvester.mass = 0.1
harvester.animations = {
	idle = {10},
	walk = {11,11,11,11,12,12,12,12},
	jump = {11}
}
harvester.primarydesc = "shotgun"
harvester.primary = {}
	harvester.primary[1] = {
		parent = "",
		sprite = 13,
		sfx = 4,
		mass = 1,
		maxage = 5,
		bounce = false,
		damage = 47,
		firedelay = 15,
		velocity = {x = 5,y = 0},
		sca = {x = 1,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
	harvester.primary[2] = {
		parent = "",
		sprite = 13,
		sfx = 4,
		mass = 1,
		maxage = 5,
		bounce = false,
		damage = 47,
		firedelay = 15,
		velocity = {x = 5,y = -2},
		sca = {x = 1,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
	harvester.primary[3] = {
		parent = "",
		sprite = 13,
		sfx = 4,
		mass = 1,
		maxage = 5,
		bounce = false,
		damage = 47,
		firedelay = 10,
		velocity = {x = 5,y = -1},
		sca = {x = 1,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
harvester.alternatedesc = "teleport"
harvester.alternate = {}
	harvester.alternate[1] = {
		parent = "",
		sprite = 14,
		sfx = 999,
		mass = 0,
		maxage = 15,
		bounce = false,
		damage = 0,
		firedelay = 40,
		velocity = {x = 0,y = 0},
		sca = {x = 8,y = 4},
		pixeloffset = {x = -8,y = 4}
	}
	harvester.alternate[2] = {
		parent = "",
		sprite = 14,
		sfx = 999,
		mass = 0,
		maxage = 15,
		bounce = false,
		damage = 0,
		firedelay = 40,
		velocity = {x = 0,y = 0},
		sca = {x = 8,y = 4},
		pixeloffset = {x = 56,y = 4}
	}

------------------robogirl----------------------
robogirl = {}
robogirl = copy(char_template)
robogirl.character = "robogirl"
robogirl.class = "tank"
robogirl.mass = 1
robogirl.hp = 200
robogirl.maxhp = 200
robogirl.shields = 200
robogirl.maxshields = 200
robogirl.animations = {
	idle = {26},
	walk = {27,27,27,28,28,28},
	jump = {27}
}
robogirl.primarydesc = "flak cannon"
robogirl.primary = {}
	robogirl.primary[1] = {
		parent = "",
		sprite = 29,
		sfx = 4,
		mass = 1,
		maxage = 5,
		bounce = false,
		damage = 10,
		firedelay = 15,
		velocity = {x = 5,y = 0},
		sca = {x = 1,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
	robogirl.primary[2] = {
		parent = "",
		sprite = 29,
		sfx = 4,
		mass = 1,
		maxage = 5,
		bounce = false,
		damage = 10,
		firedelay = 15,
		velocity = {x = 5,y = -2},
		sca = {x = 1,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
	robogirl.primary[3] = {
		parent = "",
		sprite = 29,
		sfx = 4,
		mass = 1,
		maxage = 5,
		bounce = false,
		damage = 10,
		firedelay = 10,
		velocity = {x = 5,y = -1},
		sca = {x = 1,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
robogirl.alternatedesc = "shield"
robogirl.alternate = {}
	robogirl.alternate[1] = {
		parent = "",
		sprite = 30,
		sfx = 999,
		mass = 1,
		maxage = 1,
		bounce = false,
		damage = 0,
		firedelay = 0,
		velocity = {x = 0,y = 0},
		sca = {x = 8,y = 5},
		pixeloffset = {x = 0,y = 0}
	}


--------------------------sk8rboi----------------------
sk8rboi = {}
sk8rboi = copy(char_template)
sk8rboi.character = "sk8rboi"
sk8rboi.class = "support"
sk8rboi.speed *= 2
sk8rboi.hp = 200
sk8rboi.maxhp = 200
sk8rboi.animations = {
	idle = {42},
	walk = {43,43,43,43,43,44,44,44,44,44},
	jump = {43}
}
sk8rboi.primarydesc = "soundblast"
sk8rboi.primary = {}
	sk8rboi.primary[1] = {
		parent = "",
		sprite = 45,
		sfx = 2,
		mass = 0.1,
		maxage = 15,
		bounce = false,
		damage = 16,
		firedelay = 5,
		velocity = {x = 4,y = 0},
		sca = {x = 1,y = 3},
		pixeloffset = {x = 0,y = 2}
	}
sk8rboi.alternatedesc = "sonicwave"
sk8rboi.alternate = {}
	sk8rboi.alternate[1] = {
		parent = "",
		sprite = 45,
		sfx = 2,
		mass = 0.1,
		maxage = 10,
		bounce = false,
		knockback = true,
		damage = 20,
		firedelay = 25,
		velocity = {x = 5,y = 0},
		sca = {x = 1,y = 8},
		pixeloffset = {x = 0,y = 0}
	}

--------------------------farout----------------------
farout = {}
farout = copy(char_template)
farout.character = "farout"
farout.class = "offense"
farout.hp = 200
farout.maxhp = 200
farout.canfly = true
farout.mass *= 0.25
farout.animations = {
	idle = {48},
	walk = {49,49,49,49,50,50,50,50},
	jump = {49}
}
farout.primarydesc = "rocket"
farout.primary = {}
	farout.primary[1] = {
		parent = "",
		sprite = 51,
		sfx = 3,
		mass = 0.1,
		maxage = 40,
		bounce = false,
		damage = 100,
		firedelay = 20,
		velocity = {x = 5,y = 3},
		sca = {x = 5,y = 2},
		pixeloffset = {x = 0,y = 3},
		explode = true
	}
farout.alternatedesc = "concussion"
farout.alternate = {}
	farout.alternate[1] = {
		parent = "",
		sprite = 52,
		sfx = 11,
		mass = 0.1,
		maxage = 20,
		bounce = false,
		knockback = true,
		damage = 0,
		firedelay = 25,
		velocity = {x = 5,y = 3},
		sca = {x = 3,y = 1},
		pixeloffset = {x = 0,y = 0}
	}

--maps-----------------------------
-----------------------------------
factory = {
	name = "factory",
	bgcolor = 1,
	cel = {
		x = 0,
		y = 0
	},
	dim = {
		x = 64,
		y = 32
	}
}
zinra = {
	name = "zinra",
	bgcolor = 6,
	cel = {
		x = 0,
		y = 33
	},
	dim = {
		x = 64,
		y = 31
	}
}
cloud = {
	name = "cloud city",
	bgcolor = 5,
	cel = {
		x = 64,
		y = 0
	},
	dim = {
		x = 64,
		y = 32
	}
}

--all things tables
all_characters = {soldier24, filthmouse, rainhorse, spiderlady, grace, zohan, harvester, robogirl, sk8rboi, farout}
all_maps = {factory, zinra, cloud}

__gfx__
066f0000066f0000066f000095500000c1660000225500002255000022550000777777660cc00000005550000055500000555000200000000800800800000000
06f8000006f8000006f8000000000000c1550000225800002258000022580000000000005005000000557000005570000055700000000000280280280000e000
01150000011500000115000000000000000000002e6666662e6666662e666666000000000000000005557f5505557f5505557f550000000080280282000e8800
0cc666660cc666660cc6666600000000000000002e5650002e5650002e5650000000000000000000056550000565500005655000000000002222222200e8e880
0c1156000c1156000c1156000000000000000000055e0000055e0000055e0000000000000000000005666f5505666f5505666f55000000000000000000088820
055500000555000005550000000000000000000006e6000006e6000006e600000000000000000000051115005511150055111500000000000000000000008200
05050000050500000505000000000000000000000505000005050000050500000000000000000000051510005510100055101000000000000000000000000000
06060000600600000660000000000000000000000505000050050000055000000000000000000000051510005100100050110000000000000000000000000000
0000060000000600000006000660000005000005770a9a00770a9a00000a9a0009000000a900000000eeee0000eeee0000eeee00a0000000cc0c0c0000ee0000
0006660000066600000666000066500050050500a779af00a779af007709af00aa999999000000000eeeeee50eeeeee50eeeeee5000000000300000000080000
06065a0606065a0606065a060065650009505a950a7afe050a7afe05a77afe050900000000000000eeee2cc0eeee2cc0eeee2cc000000000cccc0c0ce8000000
0666556606665566066655660650500059a599a900a6665000a666500a76665000000000000000005e2255555e2255555e225555000000003003000000000800
056666650566666505666665650000005a999a95000775700007757000a77570000000000000000000ee2200aee0220090ee200000000000ccccc0c0e8800882
005f560f005f560f005f560f500000000a9a9a900006560000065600000656000000000000000000000ee22000ee0220000ee200000000000000000000888882
0005650000056500000565000000000000aaaa00000506000005060000050600000000000000000000ee22000ee0220000ee2000000000000000000000082000
00050500005005000005500000000000000aa000000606000060600000606000000000000000000000e020000e00200000e20000000000000000000000000820
00a9a90000a9a90000a9a900090000000880000005a5500005a5500005a550005666700050005005009a5500009a5500009a5500b000000000000000e0000008
000aff00000aff00000aff009890000055550000005ff060005ff060005ff060000000000550000509a44b0009a44b0009a44b00b00000000000000000000000
060ff700060ff700060ff7000900000000000000075fe006075fe006075fe0060000000009505a900a04445b0a04445b0a04445bb00000000000000000000000
005a555a005a555a005a555a000000000000000006c1fff606c1fff606c1fff60000000055a59a5000aa555b00aa555b00aa555bb00000000000000000000000
005ff500005ff500005ff500000000000000000006cc500606cc500606cc5006000000005999995000a4450000a4450000a44500b000000000000000e0000082
060999000609990006099900000000000000000006111006061110060611100600000000059aa9a0000111000001110000011100b00000000000000000000000
00090700000907000009070000000000000000000010106000101060001010600000000000a9aa00000101000001010000010100b00000000000000000080000
000707000070070000077000000000000000000000505000050050000055000000000000000aa000000b0b0000b00b00000bb000b0000000bbbbbbbb00000002
0ccc90000ccc90000ccc9000a96660001ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000
001199000011990000119900a9555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050050505
0c1440000c1440000c14400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009505990
c1c55555c1c55555c1c5555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055a59950
c0cc5000c0cc5000c0cc500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999a50
c0111000a011100090111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000059aa950
00101000001010000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa00
005050000500500000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa000
00770000666666660767665000000000000000000000000007666650076666500777665007bbbb30077000000bbbb33000007700000770000777665000000000
076677777ddd7ddd0766565077777500777777770077777777775550077755550500005007bbbb300bbb7b770777bb3077777670007665007666666500000000
07667666d7ddd7dd076665506756655076667666077667767776655007766656077666500bbbb3300bb3bbbb0666b33076677660076666507666666500000000
06666667dd7ddd6d0776665065656650666766670767665667676650076766560500005007bbbb300bb3bbbb07766b3066656660766776660776655000000000
07665656ddd6ddd607676650656656506656665607667656656656500766565607776650077bb3300bb3bbbb0666653066557660666765650767665000000000
066655666ddd6ddd076656506566655065666566076665566566655007666556050000507bbbbb330bb33b3b0767665065656650056656500766565000000000
05665555d6ddd6dd076665505755555055555555077755555555550000755555076766507b3b33330bb333330666655055556650005665000766655000000000
00550000dd6ddd6d0776665007766650000000000776665000000000000000000500005000000000033000000776665000005500000660000776665000000000
3b3b3b3344442444000bb3b33b3b30000ff424444444242007bbb330000000000ff44220000000000000077044442444444424200f4424440000000000000000
b333b33b424444440bb333333333b3000f4444444424424007bb3b30000000000f000020777b7b7777777bb042444442424444200f4444420000000077bbbbb3
323353354444444400b35335b23333300f444444444444200bbbb330000000000fff4420bbbbbbbbbbbbbb30444242444442424004424244000000007bbbbbb3
23232323444444240b332323232b3b3004f444244444242007bbbb30000000000f000020bbbbbbbbbbbbbbb042442444424424200f44444400e000000b3b3330
424242424444444403b2424242424b330f444444444442400bbbb330000665000ff4f420bb3bbb3bbbbbbb3024222424242224200f4224240e88000007bbbb30
4444444444442444b3324444444444b00f442444244424200bbb3b30066655500f0000203bb333b33bb3bb30222022222220220000404222e88220e00bbbbb30
4444424424444444032442444444424304f444444444442007bbb330666566500ff44220333333333333333020002002200020000000400200400e8207bbbb30
244444444444444402444444244444400f4444444444242007bbb330665565550f000020000000000000033000000000000000000000000000f0004007bbbb30
6500656666506665066665666656500656666656666656666565006505aaaa900eee88200666cc10760776600767766007677660767776670777766077776777
6500656500656506565000650656500656500650065006500065006556000065eee88882666cccc1776777760776777677677770776777760770006077767776
6500656500656506566650656506565656666650065006500066666565600656ee88822266ccc111776776770776767777677670776776770777676067677760
6500656500656506565000650656565656500650065006500065006560566506e0082002600c1001767777670777776776777760767777670700066006777677
6666656500656665066665650656666656500650065006666565006560055006e0082002600c1001777777670777776777777760777777670776776077776777
0000000aaa900000000000000000000000aaa9000000000000000000600000060e88822006ccc110777776770777767777777670777776770770006077767776
00000000a90000000000000000000000000a90000000000000000000560000650e88882006cccc10776677760076677677667700776677760776776067677760
00000000000000000000000000000000000000000000000000000000056666500082820000c1c100660007600000076066000000667777670700066006777677
000a000000000000000000000000000000000000078007c000000000000000000000000000000000000000000077660076777667000000000077770077776777
0000a000000000000000000000000000000000007778777c00000000000000000000000000000000000000000776777077677776007000000776777077767776
000a000000000000000000000000000000000000078007c000000000000000000000000000000000000000007767766077767776076700000767776067677760
0000a000000000000000000000000000000000000000000000000000000000000000000000000000000777007777677677767666007000700677767706777670
000a0000000000000000000000000000000000000000000000000000000000000000000000000000077777607677777606666600076607677777677707776770
0000a000000000000000000000000000000000000000000000000000000000000000000000000000777776700777776000000000766660707776777607767770
000a0000000000000000000000000000000000000000000000000000000000000000000000000000776677760076660000000000006007666767776000677700
0000a000cccccccc8888888899999999000000000000000000000000000000000000000000000000667777670000000000000000006000600677767700000000
f5a4959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595959595a5f5
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65001717171717171717171717f5000000000000000000000000000000000000000000000000000000000000000000000000f527272727272727272727270065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65850505050505050505050505053500000000000000000000000000000000000000000000000000000000000000000000250505050505050505050505058565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65851515151515151515151515155500e50000000000000000000000000000000000000000000000000000000000000000451515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65851515151515151515151515150505053500000000000000000000000000000000000000000000000000000000250505051515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6585151515151515151515151515151515550075000000000000000000000000000000000000000000000000e500451515151515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65851515151515151515151515151515150505053500000000000000000000000000000000000000000000250505051515151515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
658515151515151515151515151515151515151555e5000000000000000000000000000000000000007500451515151515151515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
658515151515151515151515151515151515151505050535000000a495a500000000a495a5000000250505051515151515151515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
658515151515151515151515151515b515b515b515b515c500000000000000000000000000000000d515b515b515b515b5151515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65851515151515151515151515155500650065006500650000000000000000000000000000000000006500650065006500451515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65851515151515151515151515155500650094006500940000000000000000000000000000000000009400650094006500451515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65851515151515151515151515155500940000006500000000373737373737373737373737373700000000650000009400451515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65851515151515151515151515155500000000009400000000850505050505858525050505058500000000940000000000451515151515151515151515158565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6585b5b5b5b5b5b5b5b5b5b5b5b5c50000000000000000000085b5b5b5b5c58585d5b5b5b5b58500000000000000000000d5b5b5b5b5b5b5b5b5b5b5b5b58565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65850000000000000000000000000700000000000000000000854747474747474747474747478500000000000000000000070000000000000000000000008565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65850000000000000000000000000700000000000000000000854747474747474747474747478500000000000000000000070000000000000000000000008565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65850000000000000000000000000700000000000000000000474747474747474747474747474700000000000000000000070000000000000000000000008565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65851717171717171717171717177500000000000000000000474747474747474747474747474700000000000000000000752727272727272727272727278565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002323000023
65050505050505050505050505050535000000000000000000373737373737373737373737373700000000000000000025050505050505050505050505050565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023000000
651515151515151515151515151515053500000000000000f52505050505050505050505050535f5000000000000002505151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023000000
65151515151515151515151515151515053500e5000000f565451515151515151515151515155565f50000e50000250515151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002323000000
65151515151515151515151515151515150505050505050505151515151515151515151515151505050505050505051515151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002300000003
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000080808080808080804080808080808000808080808080800040808080808000800000000000000000000080808080408000102008080080000000008000008080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
454444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444436f6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f71717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000707272727272727272726f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f6a6a6a6a6a6a6a6a7b006e6a6a6a6a6a6a6a6e00000000000000000000000000000000000000000000006e6a6a6a6a6a6a6a6e007b6a6a6a6a6a6a6a6a6a6f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f000000000000000070006e000000000000006e00000000000000000000000000000000000000000000006e000000000000006e00700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f000000000000000070006e000000000000006e00000000000000000000000000000000000000000000006e000000000000006e00700000000000000000006f
420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000426f00000000000000007000000000000000000000000000000073737373737373737373737373730000000000000000000000000000700000000000000000006f
42484444444c000000404444444c000040444444444c000000000000000000000000000000000000000040444444444c0000404444444c0000004044444448426f000000000000000070000000000000000000000000006e7e6e6a6a6a6a6a6e6e6a6a6a6a6a6e7e6e000000000000000000000000700000000000000000006f
4248000000700000000000000000000000000000000000004b73737373737400007473737373734b0000000000000000000000000000000000007000000048426f717171717171717170000000000000000000000000006e6f6e7474747474747474747474746e6f6e000000000000000000000000707272727272727272726f
4248000000700000000000000000000000000000000000484544444444444c7474404444444444434800000000000000000000000000000000007000000048426f6a6a6a6a6a6a6a6a7b000000000000000000000000006e6f74747474747474747474747474746f6e0000000000000000000000007b6a6a6a6a6a6a6a6a6a6f
424800000070000000000000000000000000000000000048427474747474747474747474747474424800000000000000000000000000000000007000000048426f000000000000000070000000000000000000000000006e6f74747474747474747474747474746f6e000000000000000000000000700000000000000000006f
424871717170000000000000000000000000000000000048427474747474747474747474747474424800000000000000000000000000000000007072727248426f000000000000000070000000000000000000000000006e6f74747474747474747474747474746f6e000000000000000000000000700000000000000000006f
4244444444444c4800000000000000000000000000000048427474747474747474747474747474424800000000000000000000000000000048404444444444426f000000000000000070000000000000000000000000006e6f74747474747400747474747474746f6e000000000000000000000000700000000000000000006f
420000000000704800000000000000000000000000000048477474747474744d4d747474747474464800000000000000000000000000000048700000000000426f000000000000000070000000000000000000000000006e7f74747474000074747474747474747f6e000000000000000000000000700000000000000000006f
4200000000007048000000004044444444444c00000000000074747474747474747474747474740000000000004044444444444c0000000048700000000000426f71717171717171717000000000000000000000000000000074747474007373737374747474747400000000000000000000000000707272727272727272726f
420000000000704800000000000000000000000000000000747474747474747474747474747474740000000000000000000000000000000048700000000000426f6a6a6a6a6a6a6a6a7b00000000000000000000000000000074740073736a6a6a6a737374747400000000000000000000000000007b6a6a6a6a6a6a6a6a6a6f
420071717171704800000000000000000000000000000000747474747474747474747474747474740000000000000000000000000000000048707272727200426f0000000000000000000000000000000000000000000000007373736a6a6d6d6d6d6a6a7373730000000000000000000000000000000000000000000000006f
42484444444444444c0000000000000000000000000000007373737373734b4b4b4b7373737373730000000000000000000000000000004044444444444448426f00000000000000000000000000000000000000000000007e6a6a6a6d6d6d6d6d6d6d6d6a6a6a7e00000000000000000000000000000000000000000000006f
424800000000000070000000000000000000000000000000454444444444444444444444444444430000000000000000000000000000007000000000000048426f0000000000000000000000000000000000000000007d7e6f6d6d6d6d6d6d6d6d6d6d6d6d6d6d6f7e7d0000000000000000000000000000000000000000006f
424800000000000070000000000000000000000000000045464141414141414141414141414141474300000000000000000000000000007000000000000048426f0000000000000000000000000000000000000000007e6f6f6d6d6d6d6d6d6d6d6d6d6d6d6d6d6f6f7e0000000000000000000000000000000000000000006f
424800000000000070000000004544444443000000004546414141414141414141414141414141414743000000004544444443000000007000000000000048426f000000000000000000000000000000000000007d7e6f6f6f6d6d6d6d6d6d6d6d6d6d6d6d6d6d6f6f6f7e00000000000000000000000000000000000000006f
4248717171717171700000004b47434e45464b00004546414141414141414141414141414141414141474300004b47434e45464b0000007072727272727248426f007a0000007d00000000007a7d0000007d00007e6f6f6f6f6d6d6d6d6d6d6d6d6d6d6d6d6d6d6f6f6f6f7e000000007a0000007d0000007a7d00000000006f
474141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141466b6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6d6d6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6c
__sfx__
010400001f02001000010000100001000010000100001000010000100001000010000100001000010000200001000010000100001000000000000000000000000f00000000000000000000000000000000000000
000a0000130701e040240302b0102b0002b0002a00025000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000c5700c6000c6000c6000c6000c6000c6000c6000c6000340003400044000440003500055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000364005640086300862007610056100461003610016100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c6100a610086100461001610016000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002406023060210601f0601f0611f0611f0611f0612400023000210001f0001f0011f0011f0011f00100000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00001f0602106023060240602406124051240412403124000180001a0001f0001c000210002300024000180001a0001c000210001f000240001c0002400021000180001a000180001a0001c0001f00021000
012a00000014400145001040010500004000050000400005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003901100000390140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003
010200001332213311135111351113511135111351100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001504007041040310002104011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000230302d0212b0212901128011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000b1300e6201c1101f61021110006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011300000613306133061020610109133091330910209101061330613306102061010d1330d1330d1020d101091330913309102091010c1330c1330c1020c1010613306133061020610104133041330410204101
011300000d7550d7551a000000000d7640d76400000000000e7550e75500000000000e7640e764000000000010755107550000000000107641076400000000001275512755000000000012764127640000000000
011300001275212752127521275412702127521275212754157521575215752157541470214752147521475412752127521275212754127021275212752127541775217752177521775415702157521575215754
0113000025520285202a5203670028520377002a52034700285202a5202750028520357002770000000000002852000000255200000028520000002a520000002d5202a5202d7000000000000000000000000000
0113000025520285202a5203670028520377002a5203470028520365002d52028520357002770000000000002852000000255200000028520000002d5202a520255202a5202d7000000000000000000000000000
0112181821700217012170121701217011f705217050000521705000052170019705215041d505215041d505215041d505215041d505235041d505215041d505215041e505215041e505215041e505215041e505
011800182d715285142d715285142d715285142d715285142f715285142d715285142d715295142d715295142d715295142d715295142b715295142d71529514287051c505215051c505215051c505215051c505
011800182d7152a5142d7152a5142d7152a5142d7152a5142f7152a5142d7152a5142d715295142d715295142d715295142d715295142b715285142b7152d514287042b7002b700000002b704000000000028704
011800182172021711217112171121711217112171121711217112171121701217011d7201d7111d7111d7111d7111d7111d7111d7111d7111d71100000000001a7001a7011a7011a701000001c7011c7011c701
011800181a7201a7111a7111a7111a7111a7111a7111a7111a7111a71100000000001d7201d7111d7111d7111d7111d7111d7111d7111d7111d71100000000000000000000000000000000000000000000000000
0118000024750247412474124741247412470524705247052474524700247452470021750217412174121741217411f7052170500000217450000021745000000000000000000000000000000000000000000000
011800001a7501a7411a7411a7411a741247051a705247051a745247051a745247051d7501d7411d7411d7411d7011f7051f745000051f7450000521740197050000000000000000000000000000000000000000
011800180975009751097510975109741097410974109741097410974109741097410c7500c7510c7510c7510c7410c7410c7410c7410c7410c7410c7410c7411c7001c7011c7011c7011c7011c7011c7011c701
011800000e7500e7510e7510e7510e7410e7410e7410e7410e7410e7410e7410e7411175011751117511175111741117411375013751137511375113741137410000000000000000000000000000000000000000
011800002d714285152d714285152d714285152d7142d7112d7112d7112d7012d7012d714295152d714295152d714295152d7142d7112d7112d7112d704295050000000000000000000000000000000000000000
011800002d7142a5152d7142a5152d7142a5152d7142a5152f7142a5152d7142a5152d714295152d714295152d714295152b7142b7112b7112b7112b7042d5050000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200416504165041650416504105041050616506165071650716507165071650000000000071650716500105001050716507165001050010507165071650916509165091650916505105021050b1650b165
0120000021754217412173121721217112171121711217111f7041f7011f7011f7011f7541f7411f7311f7211c7541c7411c7311c7211c7111c7111c7111c711000001c701000001c70100000000000000000000
011000001c7041c7041c7241c7241a7251a7251c7241c7241c7041c7041c7241c7241a7251a7251c7241c7241c7041c7041c7241c7241a7251a7251c7241c7241c7041c7041c7241c7241a7251a7251c7241c724
012000002d7152d7142d7152d7142d7152d7142d7152d7142d7152d7142d7152d7142d7152d7142d7152d7142b7152b7142b7152b7142b7152b7142b7152b7142b7152b7142b7152b7142b7152b7142b7152b714
012000002d7152d7142d7152d7142d7152d7142d7152d7142d7152d7142d7152d7142d7152d7142d7152d71428715287142871528714287152871428715287142871528714287152871428715287142871528714
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 20422244
00 20212244
01 20242223
02 20212224
00 25262863
00 25272944
01 2526282a
00 2527292b
00 25262c2a
00 25272d2b
00 252e2c2a
00 252f2d2b
00 2526282c
02 2527292d
00 41424344
00 31327344
01 31323344
00 31323334
02 31323335
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

