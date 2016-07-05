pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--underwatch v0.10
--author: n33kos

--globals-------------------------------------
----------------------------------------------
ai_entities = {}
player_entities = {}
projectiles = {}

drag = {1.05,1.05}
bounce = {0.9,0.9}
gravity = {0,-0.30}
time = 0

cam = {}
cam.pos = {x = 64, y = 128}
cam.offset = {x = 64, y = 110}
cam.followdistance = {x = 1, y = 8}

game = {
	currmap = {},
	firstload = true,
	state = "title",
	menuselection = 0,
	selectedcharacter = 0,
	selectedmap = 0,
	ispaused = false,
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
		capturespeed = 0.4,
		controlspeed = 0.1,
		team1_on_point = {},
		team2_on_point = {}
	}
}
--creation functions-----------------------------------
---------------------------------------------------
function make_player()
	temp_entity = copy(all_characters[flr(game.selectedcharacter%#all_characters)+1])
	--temp_entity.ismortal = false -- god mode
	temp_entity.isplayer = true
	temp_entity.team = "team1"
	for key,val in pairs(temp_entity.primary) do
		val.parent = "team1"
		val.firedelay *= game.maxfirerate - game.globalfirerate
	end
	for key,val in pairs(temp_entity.alternate) do
		val.parent = "team1"
		val.firedelay *= game.maxfirerate - game.globalfirerate
	end
	spawn = find_spawn_point(temp_entity)
	temp_entity.pos.x = spawn[1]
	temp_entity.pos.y = spawn[2]
	add(player_entities, temp_entity)
	cam.target = temp_entity
end

function make_ai()
	--team 1
	for i=1,5 do
		temp_entity = copy(all_characters[flr(rnd(#all_characters))+1])
		temp_entity.team = "team1"
		for key,val in pairs(temp_entity.primary) do
			val.parent = "team1"
			val.firedelay *= game.maxfirerate - game.globalfirerate
		end
		for key,val in pairs(temp_entity.alternate) do
			val.parent = "team1"
			val.firedelay *= game.maxfirerate - game.globalfirerate
		end
		spawn = find_spawn_point(temp_entity)
		temp_entity.pos.x = spawn[1]
		temp_entity.pos.y = spawn[2]
		add(ai_entities, temp_entity)
	end
	--team 2
	for i=1,6 do
		temp_entity = copy(all_characters[flr(rnd(#all_characters))+1])
		temp_entity.team = "team2"
		for key,val in pairs(temp_entity.primary) do
			val.parent = "team2"
			val.firedelay *= game.maxfirerate - game.globalfirerate
		end
		for key,val in pairs(temp_entity.alternate) do
			val.parent = "team2"
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

	if temp_proj.pos.x > cam.pos.x and temp_proj.pos.x < cam.pos.x+128 and temp_proj.sfx != 999 and entity.isplayer then
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
	if entity.pos.x < 192 then
		entity.velocity.x += rnd(entity.speed)+rnd(entity.speed)
	elseif entity.pos.x > 312 then
		entity.velocity.x -= rnd(entity.speed)+rnd(entity.speed)
	else
		if type(entity.target) then
			if entity.target.pos.x > entity.pos.x then
				entity.velocity.x += rnd(entity.speed)+rnd(entity.speed)
			else
				entity.velocity.x -= rnd(entity.speed)+rnd(entity.speed)
			end
			if entity.isjumping != true and (rnd(10) < 1 or (entity.velocity.x < 0.2 and entity.velocity.x > -0.2)) then
				entity.velocity.y -= rnd(entity.jumpheight)
			end
		else
			entity.target = ai_get_target(entity)
		end
	end
	if entity.isjumping != true and (rnd(10) < 0.25 or (entity.velocity.x < 0.2 and entity.velocity.x > -0.2)) then
		entity.velocity.y -= rnd(entity.jumpheight)
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
		if entity.shottimer <= 0 and time%2 == 0 then
			for key,val in pairs(entity.primary) do
				entity.shottimer = val.firedelay
				make_projectile(entity, val)
			end
		end
		if entity.alternateshottimer <= 0 and time%2 == 1 then
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
	otherteam = {}
	for key,otherentity in pairs(ai_entities) do
		if entity.character == "grace" then
			if otherentity.team == entity.team then
				add(otherteam, otherentity)
			end
		else
			if otherentity.team != entity.team then
				add(otherteam, otherentity)
			end
		end
	end
	closest_target = nil
	for key,val in pairs(otherteam) do
		if entity.character == "grace" then
			if closest_target == nil or val.hp/val.maxhp < closest_target.hp/closest_target.maxhp then
				closest_target = val
			end
		else
			if closest_target == nil or abs(val.pos.x - entity.pos.x) < abs(closest_target.pos.x - entity.pos.x) then
				closest_target = val
			end
		end
	end
	return otherteam[flr(rnd(#otherteam))+1]
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
		entity.velocity.y = 0
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
		entity.velocity.y *= -bounce[2]
		entity.pos.y = flr((top[2]+1)*8) -- make sure the entity stays within bounds
	end

	--left
	val = mget(left[1]+game.currmap.cel.x, left[2]+game.currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= -bounce[1]
		entity.pos.x = flr((left[1]+1)*8) -- make sure the entity stays within bounds
	end

	--right
	val = mget(right[1]+game.currmap.cel.x, right[2]+game.currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= -bounce[1]
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
			if bullet.bounce then
				bullet.velocity.y *= -bounce[2]
			end
			bullet.pos.y = (bottom[2]-1)*8 -- make sure the bullet stays within bounds
		end

		--left
		val = mget(left[1]+game.currmap.cel.x, left[2]+game.currmap.cel.y)
		if fget(val, 7) == true then
			if bullet.bounce then
				bullet.velocity.x *= -bounce[1]
			end
			bullet.pos.x = (left[1]+1)*8 -- make sure the bullet stays within bounds
		end

		--right
		val = mget(right[1]+game.currmap.cel.x, right[2]+game.currmap.cel.y)
		if fget(val, 7) == true then
			if bullet.bounce then
				bullet.velocity.x *= -bounce[1]
			end
			bullet.pos.x = (right[1]-1)*8 -- make sure the bullet stays within bounds
		end

		--top
		val = mget(top[1]+game.currmap.cel.x, top[2]+game.currmap.cel.y)
		if fget(val, 7) == true then
			if bullet.bounce then
				bullet.velocity.y *= -bounce[2]
			end
			bullet.pos.y = (top[2]+1)*8 -- make sure the bullet stays within bounds
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
	val = mget(flr((entity.pos.x+entity.sca.x/2)/8)+game.currmap.cel.x, flr((entity.pos.y+entity.sca.y/2)/8)+game.currmap.cel.y)
	if fget(val, 6) == true then
		entity.onladder = true
		entity.isjumping = false
		entity.velocity.y = 0
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
		entity.ismortal and 
		bullet.damage != 0 and
		bullet.damage != nil and 
		((bullet.damage > 0 and bullet.parent != entity.team) or 
		(bullet.damage < 0 and bullet.parent == entity.team)) then
			if bullet.explode then
				for i=0,1 do
					explosion.parent = bullet.parent
					make_projectile(bullet, explosion)
				end
			end
			if entity.shielded and entity.shields > 0 then
				entity.shields -= bullet.damage
			else
				entity.hp -= bullet.damage
			end
			del(projectiles, bullet)
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

function move_camera()
	if cam.target then
		cam.pos.x = cam.pos.x + (cam.target.pos.x - (cam.pos.x+cam.offset.x))/cam.followdistance.x
		cam.pos.y = cam.pos.y + (cam.target.pos.y - (cam.pos.y+cam.offset.y))/cam.followdistance.y
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
	if entity.current_animation == "idle" then
		entity.sprite = entity.animations.idle[time % #entity.animations.idle+1]
	end
	if entity.current_animation == "walk" then
		entity.sprite = entity.animations.walk[time % #entity.animations.walk+1]
	end
	if entity.current_animation == "jump" then
		entity.sprite = entity.animations.jump[time % #entity.animations.jump+1]
	end
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
	--rectfill(cam.pos.x+59, cam.pos.y, cam.pos.x+69, cam.pos.y+6, 5)
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

function draw_menu()
	--window
	rectfill(cam.pos.x+8, cam.pos.y+8, cam.pos.x+120, cam.pos.y+120, 0)
	rect(cam.pos.x+6, cam.pos.y+6, cam.pos.x+122, cam.pos.y+122, 1)
	rect(cam.pos.x+8, cam.pos.y+8, cam.pos.x+120, cam.pos.y+120, 12)

	--logo
	sspr(0, 48, 56, 8, cam.pos.x+15, cam.pos.y+15, 100, 12)

	print("press z or x to play", cam.pos.x+20, cam.pos.y+30, 7)

	--settings
	selectedchar = all_characters[flr(game.selectedcharacter%#all_characters)+1]

	menu = {
		"capture speed: "..game.globalgamespeed.."x",
		"gravity: "..game.globalgravity.."x",
		"fire rate: "..game.globalfirerate.."x",
		"map: "..all_maps[flr(game.selectedmap%#all_maps)+1].name,
		"character: "..selectedchar.character,
	}

	for i=0,4 do
		if game.menuselection == i then
			print(menu[i+1], cam.pos.x+20, cam.pos.y+45+(i*10), 12)
		else
			print(menu[i+1], cam.pos.x+20, cam.pos.y+45+(i*10), 1)
		end
	end

	--char preview
	sspr(flr(selectedchar.animations.walk[time%#selectedchar.animations.walk+1]%16)*8, flr(selectedchar.animations.walk[time%#selectedchar.animations.walk+1]/16)*8, 8, 8, cam.pos.x+20, cam.pos.y+95, 16, 16)
	if game.menuselection == 4 then
		drcol = 12
	else
		drcol = 1
	end
	print(selectedchar.class, cam.pos.x+46, cam.pos.y+95, drcol)
	print("z - "..selectedchar.primarydesc, cam.pos.x+46, cam.pos.y+101, drcol)
	print("x - "..selectedchar.alternatedesc, cam.pos.x+46, cam.pos.y+107, drcol)


	if btnp(2) then
		game.menuselection = max(0,game.menuselection-1)
		sfx(0)
	end
	if btnp(3) then
		game.menuselection = min(#menu-1,game.menuselection+1)
		sfx(0)
	end
end

--game functions-----------------------------------
---------------------------------------------------
function assess_hp(entity, table)
	if entity.hp > entity.maxhp then
		entity.hp = entity.maxhp
	end
end

function assess_capture()
	if game.state == "play" then

		game.objective.team1_on_point = {}
		game.objective.team2_on_point = {}
		--is on point count
		for key,entity in pairs(ai_entities) do
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
		for key,entity in pairs(player_entities) do
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
		if #game.objective.team1_on_point > 0 and #game.objective.team2_on_point == 0 then
			game.objective.team1capturepercentage += game.objective.capturespeed*game.globalgamespeed*#game.objective.team1_on_point
			game.objective.team2capturepercentage -= game.objective.capturespeed*game.globalgamespeed*#game.objective.team1_on_point
		elseif #game.objective.team2_on_point > 0 and #game.objective.team1_on_point == 0 then
			game.objective.team1capturepercentage -= game.objective.capturespeed*game.globalgamespeed*#game.objective.team2_on_point
			game.objective.team2capturepercentage += game.objective.capturespeed*game.globalgamespeed*#game.objective.team2_on_point
		else
			game.objective.team1capturepercentage -= game.objective.capturespeed*game.globalgamespeed
			game.objective.team2capturepercentage -= game.objective.capturespeed*game.globalgamespeed
		end

		--control logic
		if game.objective.team1capturepercentage >= 100 then
			game.objective.team1controlpercentage += game.objective.controlspeed*game.globalgamespeed*#game.objective.team1_on_point
		elseif game.objective.team2capturepercentage >= 100 then
			game.objective.team2controlpercentage += game.objective.controlspeed*game.globalgamespeed*#game.objective.team2_on_point
		end

		--min
		if game.objective.team1capturepercentage < 0 then game.objective.team1capturepercentage = 0 end
		if game.objective.team2capturepercentage < 0 then game.objective.team2capturepercentage = 0 end
		if game.objective.team1controlpercentage < 0 then game.objective.team1controlpercentage = 0 end
		if game.objective.team2controlpercentage < 0 then game.objective.team2controlpercentage = 0 end
		--max
		if game.objective.team1capturepercentage > 100 then game.objective.team1capturepercentage = 100 end
		if game.objective.team2capturepercentage > 100 then game.objective.team2capturepercentage = 100 end

		--win logic
		if game.objective.team1controlpercentage >= 100 or game.objective.team2controlpercentage >= 100 then
			game.ispaused = true
			game.state = "score"
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


--execution---------------------------------------
--------------------------------------------------
function _init()
	cls()
end

function _update()
	if game.ispaused == false then
		--game objectives
		game.currmap = all_maps[flr(game.selectedmap%#all_maps)+1]
		assess_capture()

		--ai entities
		for key,entity in pairs(ai_entities) do
			if entity.hp > 0 then
				assess_hp(entity, ai_entities)
				cleanup(entity)
				entity.target = ai_get_target(entity)
				ai_movement_behavior(entity)
				ai_attack_behavior(entity)
				if entity.onladder == false then
					apply_gravity(entity)
				end
				apply_velocity(entity)
				apply_drag(entity)
				apply_entity_map_collision(entity)
				apply_ladder_collision(entity)
				apply_projectile_entity_collision(entity)
				set_animation_frame(entity)
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

		--player entities
		for key,entity in pairs(player_entities) do
			if entity.hp > 0 then
				cleanup(entity)
				assess_hp(entity, player_entities)
				entity.target = ai_get_target(entity)
				if entity.onladder == false then
					apply_gravity(entity)
				end
				apply_velocity(entity)
				apply_drag(entity)
				apply_entity_map_collision(entity)
				apply_ladder_collision(entity)
				apply_projectile_entity_collision(entity)
				set_animation_frame(entity)
			else
				if entity.team == "team1" then
					game.kills.team2 += 1
				else
					game.kills.team1 += 1
				end
				temp_proj = copy(splat)
				make_projectile(entity,temp_proj)
				del(player_entities, entity)
			end
		end

		--projectiles
		for key,entity in pairs(projectiles) do
			cleanup(entity)
			apply_gravity(entity)
			apply_velocity(entity)
			apply_projectile_map_collision(entity)
			projectile_anim(entity)
			entity.age += 1
			if entity.age >= entity.maxage then
				if entity.explode then
					for i=0,1 do
						make_projectile(entity, explosion)
					end
				end
				del(projectiles, entity)
			end
		end
	end
end

function _draw()
	if game.ispaused == false then
		cls()
		
		--time management
		time += 1
		if time > 2047 then time = 0 end

		--camera
		if #player_entities > 0 then
			cam.target = player_entities[1]
		elseif #ai_entities > 0 then
			cam.target = ai_entities[2]
		end
		move_camera()

		--map
		draw_map()

		--ai entities
		for key,entity in pairs(ai_entities) do
			--respawn
			if entity.hp <= 0 then
				entity.respawncounter += 1
				entity.velocity.x = 0
				entity.velocity.y = 0

				if entity.respawncounter >= game.respawntime then
					respawncounter = 0
					team = entity.team
					tmp = copy(all_characters[flr(rnd(#all_characters))+1])
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
				draw_entity(entity)
				draw_health_bar(entity)

				--special
				if entity.character == "rainhorse" and entity.shielded and entity.shields > 0 then
					if entity.spriteflip.x then
						line(entity.pos.x,entity.pos.y,entity.pos.x,entity.pos.y+entity.sca.y,12)
					else
						line(entity.pos.x+entity.sca.x,entity.pos.y,entity.pos.x+entity.sca.x,entity.pos.y+entity.sca.y,12)
					end
				end

				--resets
				if entity.character == "rainhorse" or entity.character == "robogirl" then
					entity.shielded = false
				end
			end
		end

		--player entities
		for key,entity in pairs(player_entities) do
			--draw
			draw_entity(entity)
			draw_health_bar(entity)

			--special
			if entity.character == "rainhorse" and entity.shielded and entity.shields > 0 then
				if entity.spriteflip.x then
					line(entity.pos.x,entity.pos.y,entity.pos.x,entity.pos.y+entity.sca.y,12)
				else
					line(entity.pos.x+entity.sca.x,entity.pos.y,entity.pos.x+entity.sca.x,entity.pos.y+entity.sca.y,12)
				end
			end

			--resets
			if entity.character == "rainhorse" or entity.character == "robogirl" then
				entity.shielded = false
			end
		end

		--projectiles
		for key,entity in pairs(projectiles) do
			draw_entity(entity)
		end

		--player respawn counter
		if #player_entities == 0 then
			game.respawncounter += 1
			sspr(flr(104%16)*8, flr(104/16)*8, 8, 8, cam.pos.x+56, cam.pos.y+50, 16, 16)
			print(flr((game.respawntime-game.respawncounter)/30)+1, cam.pos.x+62, cam.pos.y+60, 7)
			if game.respawncounter >= game.respawntime then
				game.respawncounter = 0
				make_player()
			end
		end

	end

	--gui----------------------------------------
	---------------------------------------------
	if game.state == "title" then
		rectfill(cam.pos.x+8, cam.pos.y+28, cam.pos.x+120, cam.pos.y+84, 0)
		rect(cam.pos.x+6, cam.pos.y+26, cam.pos.x+122, cam.pos.y+86, 1)
		rect(cam.pos.x+8, cam.pos.y+28, cam.pos.x+120, cam.pos.y+84, 12)

		--logo
		sspr(56, 48, 8, 8, cam.pos.x+54, cam.pos.y+40, 16, 16)
		sspr(0, 48, 56, 8, cam.pos.x+15, cam.pos.y+60, 100, 12)

		print("press any key", cam.pos.x+36, cam.pos.y+90, 12)

		if btn(0) or btn(1) or btn(2) or btn(3) or btn(4) or btn(5) then
			game.state = "menu"
		end
	elseif game.state == "menu" then
		if game.firstload then
			time = 0
			game.kills.team1 = 0
			game.kills.team2 = 0
			game.objective.team1capturepercentage = 0
			game.objective.team2capturepercentage = 0
			game.objective.team1controlpercentage = 0
			game.objective.team2controlpercentage = 0
			make_player()
			make_ai()
			game.firstload = false
		end

		draw_menu()

		if btnp(0) then
			if game.menuselection == 0 then
				game.globalgamespeed -= 0.1
			elseif game.menuselection == 1 then
				game.globalgravity -= 0.1
			elseif game.menuselection == 2 then
				game.globalfirerate = max(0.1, game.globalfirerate-0.1)
			elseif game.menuselection == 3 then
				game.selectedmap += 1
			elseif game.menuselection == 4 then
				game.selectedcharacter += 1
			end
			sfx(0)
		end
		if btnp(1) then
			if game.menuselection == 0 then
				game.globalgamespeed += 0.1
			elseif game.menuselection == 1 then
				game.globalgravity += 0.1
			elseif game.menuselection == 2 then
				game.globalfirerate = min(game.maxfirerate, game.globalfirerate+0.1)
			elseif game.menuselection == 3 then
				game.selectedmap -= 1
			elseif game.menuselection == 4 then
				game.selectedcharacter -= 1
			end
			sfx(0)
		end
		if btnp(4) or btnp(5) then
			game.state = "play"
			game.firstload = true
			sfx(1)
		end
	elseif game.state == "play" then
		game.ispaused = false

		if game.firstload then
			game.firstload = false
			time = 0
			ai_entities = {}
			player_entities = {}
			game.kills.team1 = 0
			game.kills.team2 = 0
			game.objective.team1capturepercentage = 0
			game.objective.team2capturepercentage = 0
			game.objective.team1controlpercentage = 0
			game.objective.team2controlpercentage = 0
			make_player()
			make_ai()
		end

		draw_objective_rect()
		draw_kills()

		--player feedback------------------------------------
		-----------------------------------------------------
		if btn(0) then
			--left
			for key,entity in pairs(player_entities) do
				entity.velocity.x -= entity.speed
				entity.spriteflip.x = true
			end
		end
		if btn(1) then
			--right
			for key,entity in pairs(player_entities) do
				entity.velocity.x += entity.speed
				entity.spriteflip.x = false
			end
		end
		if btn(2) then
			--up
			for key,entity in pairs(player_entities) do
				if entity.isjumping == false then
					entity.velocity.y -= entity.jumpheight
					entity.isjumping = true
				end
			end
		end
		if btn(3) then
			--down
			for key,entity in pairs(player_entities) do
				if entity.isjumping == false then
					entity.onladder = false
					entity.isjumping = true
				end
			end
		end
		if btn(4) then
			--one
			for key,entity in pairs(player_entities) do
				--counter
				entity.shottimer -= 1

				--primary fire
				if entity.shottimer <= 0 then
					for key,val in pairs(entity.primary) do
						entity.shottimer = val.firedelay
						make_projectile(entity, val)
					end
				end

			end
		elseif btn(5) then
			for key,entity in pairs(player_entities) do
				--counter
				entity.alternateshottimer -= 1

				--alternate fire
				if entity.alternateshottimer <= 0 then
					for key,val in pairs(entity.alternate) do
						entity.alternateshottimer = val.firedelay
						make_projectile(entity, val)
					end

					if entity.character == "rainhorse" or entity.character == "robogirl" and entity.shields > 0 then
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
	elseif game.state == "score" then
		game.ispaused = true
		game.firstload = true
		
		--window
		rectfill(cam.pos.x+8, cam.pos.y+12, cam.pos.x+120, cam.pos.y+120, 0)
		rect(cam.pos.x+6, cam.pos.y+10, cam.pos.x+122, cam.pos.y+122, 1)
		rect(cam.pos.x+8, cam.pos.y+12, cam.pos.x+120, cam.pos.y+120, 12)

		--logo
		sspr(0, 48, 56, 8, cam.pos.x+15, cam.pos.y+30, 100, 12)

		if game.objective.team1controlpercentage > game.objective.team2controlpercentage then
			print("win", cam.pos.x+60, cam.pos.y+50, 12)
		else
			print("defeat", cam.pos.x+55, cam.pos.y+50, 8)
		end
		
		print("kills: ", cam.pos.x+15, cam.pos.y+70, 6)
		print(game.kills.team1, cam.pos.x+60, cam.pos.y+70, 12)
		print(game.kills.team2, cam.pos.x+90, cam.pos.y+70, 8)

		print("control: ", cam.pos.x+15, cam.pos.y+80, 6)
		print(flr(game.objective.team1controlpercentage).."%", cam.pos.x+60, cam.pos.y+80, 12)
		print(flr(game.objective.team2controlpercentage).."%", cam.pos.x+90, cam.pos.y+80, 8)

		print("press z+x to restart", cam.pos.x+24, cam.pos.y+110, 1)
		if btn(4) and btn(5) then game.state = "menu" end

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
	ismortal = true,
	isalive = true,
	shielded = false,
	hp = 5,
	maxhp = 5,
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
	alternate = {},
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
	damage = 1,
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
	sfx = 3,
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
soldier24.hp = 10
soldier24.maxhp = 10
soldier24.primarydesc = "rifle"
soldier24.primary = {}
	soldier24.primary[1] = {
		sprite = 3,
		sfx = 2,
		mass = 0.1,
		maxage = 10,
		bounce = false,
		damage = 1,
		firedelay = 10,
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
		sfx = 999,
		mass = 0.5,
		maxage = 30,
		bounce = false,
		damage = 3,
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
		sfx = 999,
		mass = 1,
		maxage = 25,
		bounce = true,
		damage = 3,
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
		sfx = 999,
		mass = 2,
		maxage = 25,
		bounce = true,
		damage = 5,
		firedelay = 50,
		velocity = {x = 0.5,y = 0},
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
rainhorse.hp = 15
rainhorse.maxhp = 15
rainhorse.shields = 35
rainhorse.maxshields = 35
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
		sfx = 999,
		mass = 1,
		maxage = 2,
		bounce = false,
		damage = 3,
		firedelay = 30,
		velocity = {x = 1,y = 0},
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
spiderlady.hp = 3
spiderlady.maxhp = 3
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
		sfx = 2,
		mass = 0.1,
		maxage = 50,
		bounce = false,
		damage = 10,
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
		sfx = 999,
		mass = 1,
		maxage = 10,
		bounce = true,
		damage = 2,
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
grace.hp = 5
grace.maxhp = 5
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
		damage = -1,
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
		damage = 1,
		firedelay = 15,
		velocity = {x = 5,y = 0},
		sca = {x = 2,y = 1},
		pixeloffset = {x = 0,y = 2}
	}
		
--------------------------zohan----------------------
zohan = {}
zohan = copy(char_template)
zohan.character = "zohan"
zohan.class = "defense"
zohan.jumpheight = 5
zohan.hp = 5
zohan.maxhp = 5
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
		sfx = 999,
		mass = 1,
		maxage = 40,
		bounce = false,
		damage = 5,
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
		sfx = 999,
		mass = 1,
		maxage = 40,
		bounce = true,
		damage = 6,
		firedelay = 35,
		velocity = {x = 6,y = -2},
		sca = {x = 5,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
	zohan.alternate[2] = {
		parent = "",
		sprite = 40,
		sfx = 999,
		mass = 1,
		maxage = 40,
		bounce = true,
		damage = 6,
		firedelay = 35,
		velocity = {x = 6,y = -3},
		sca = {x = 5,y = 1},
		pixeloffset = {x = 0,y = 3}
	}
	zohan.alternate[3] = {
		parent = "",
		sprite = 40,
		sfx = 999,
		mass = 1,
		maxage = 40,
		bounce = true,
		damage = 6,
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
harvester.hp = 6
harvester.maxhp = 6
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
		damage = 1,
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
		damage = 1,
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
		damage = 1,
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
		mass = 2,
		maxage = 100,
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
		mass = 2,
		maxage = 100,
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
robogirl.hp = 10
robogirl.maxhp = 10
robogirl.shields = 15
robogirl.maxshields = 15
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
		damage = 1,
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
		damage = 1,
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
		damage = 1,
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
		maxage = 2,
		bounce = false,
		damage = 0,
		firedelay = 0,
		velocity = {x = 0,y = 0},
		sca = {x = 8,y = 5},
		pixeloffset = {x = 0,y = 0}
	}

--maps-----------------------------
-----------------------------------
factory = {
	name = "factory",
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
	cel = {
		x = 0,
		y = 33
	},
	dim = {
		x = 64,
		y = 32
	}
}

--all things tables
all_characters = {soldier24, filthmouse, rainhorse, spiderlady, grace, zohan, harvester, robogirl}
all_maps = {factory, zinra}

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
00a9a90000a9a90000a9a900090000000880000005a5500005a5500005a5500056667000500050050000000000000000000000000000000000000000e0000008
000aff00000aff00000aff009890000055550000005ff060005ff060005ff0600000000005500005000000000000000000000000000000000000000000000000
060ff700060ff700060ff7000900000000000000075fe006075fe006075fe0060000000009505a90000000000000000000000000000000000000000000000000
005a555a005a555a005a555a000000000000000006c1fff606c1fff606c1fff60000000055a59a50000000000000000000000000000000000000000000000000
005ff500005ff500005ff500000000000000000006cc500606cc500606cc500600000000599999500000000000000000000000000000000000000000e0000082
060999000609990006099900000000000000000006111006061110060611100600000000059aa9a0000000000000000000000000000000000000000000000000
00090700000907000009070000000000000000000010106000101060001010600000000000a9aa00000000000000000000000000000000000000000000080000
000707000070070000077000000000000000000000505000050050000055000000000000000aa000000000000000000000000000000000000000000000000002
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050050505
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009505990
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055a59950
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009999a50
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000059aa950
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa000
66666666555555550767665000000000000000000000000007666650076666500777665000000000000000000000000000000000000000000000000000000000
66666666666666660766565077777500777777770077777777777550077755550500005000000000000000000000000000000000000000000000000000000000
666666665555565607666550675665507666766607766776777665500776665607766650000000000000d0000000000000000000000000000000000000000000
6666666666666666077666506565665066676667076766566767665007676656050000500000d000000000000000000000000000000000000000000000000000
66666666555555550767665065665650665666560766765665665650076656560777665000000000000000000000000000000000000000000000000000000000
66666666666666660766565065666550656665660766655665666550076665560500005000000000000000000000000000000000000000000000000000000000
666666666565555607666550575555505555555507775555555555000075555507676650000000d0000000000000000000000000000000000000000000000000
6666666666666666077666500776665000000000077666500000000000000000050000500d000000000000000000000000000000000000000000000000000000
3b3b3b3344442444000bb3b33b3b30000ff424444444242007bbb330000000000ff4422000007770000000000000000000000000000000000000000000000000
b333b33b424444440bb333333333b3000f4444444424424007bb3b30000000000f00002000000000000000000000000000000000000000000000000000000000
323353354444444400b35335b23333300f444444444444200bbbb330000000000fff442000770000000007700000000000000000000000000000000000000000
23232323444444240b332323232b3b3004f444244444242007bbbb30000000000f00002000000000000000000000000000000000000000000000000000000000
424242424444444403b2424242424b330f444444444442400bbbb330000665000ff4f42000000000000000000000000000000000000000000000000000000000
4444444444442444b3324444444444b00f442444244424200bbb3b30066655500f00002000000000000000000000000000000000000000000000000000000000
4444424424444444032442444444424304f444444444442007bbb330666566500ff4422077007770000000000000000000000000000000000000000000000000
244444444444444402444444244444400f4444444444242007bbb330665565550f00002000000000000000000000000000000000000000000000000000000000
6500656666506665066665666656500656666656666656666565006505aaaa900eee88200666cc10000000000000000000000000000000000000000000000000
6500656500656506565000650656500656500650065006500065006556000065eee88882666cccc1000000000000000000000000000000000000000000000000
6500656500656506566650656506565656666650065006500066666565600656ee88822266ccc111000000000000000000000000000000000000000000000000
6500656500656506565000650656565656500650065006500065006560566506e0082002600c1001000000000000000000000000000000000000000000000000
6666656500656665066665650656666656500650065006666565006560055006e0082002600c1001000000000000000000000000000000000000000000000000
0000000aaa900000000000000000000000aaa9000000000000000000600000060e88822006ccc110000000000000000000000000000000000000000000000000
00000000a90000000000000000000000000a90000000000000000000560000650e88882006cccc10000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000056666500082820000c1c100000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000cccccccc8888888899999999000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
6595959595959595959595959595959595a59595959595959595952395959595959595959595959595959595959595959595959523a5a5a5a5a5959595a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65a5959595959595a5a5a59595959595a5a595959595959595232323a5a5a5a5a5a5a5a595959595a5239595239595952395952395959595a5a5959595a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65a5a59595959595a5a5a5a5a5959595a5a5a5a59595959595952323a5a5a5a5a5a5a5a5a52395a5a52323952395239595232323959595959595959595a52365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6523a5a595a5a5a5a5a5a523a5a5a5a523a5a5a5a59595959595952323232323232323a5a5a523a5a52323959523959523a5a5959595959595a5a59595a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
652323a523a5a52323a5a52323a5a5a59523a5a5a5a5a5a523232323232323232323f7f7f7a5a5a5f7f7f7959595a5a523a595959595959595a5a5a523a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
652323a5a5a5a523232323232323a5a59595a595a59595a5a5a5a52323232323232323232323a5a5232323a5a5a5a5a523a5a5a5a5a595959595a5a523a52365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
652323a5a523232323232323232323232323a5a5232395959595a5a523232323232323232323a5a5232323a5a5a5f7a5f7f7f7f7f7a5a5959595a5a5a5a52365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
652323a52323232323232323232323232323a5a5a52323a5959595959523232323232323232323232323a5232323a5f7a5f7f7f7f7f7a5a5a5a5a5a523a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65232323232323f7f7f7f7f7f72323232323f7a5a5a5232323a523959595a5232323232323232323232323232323a5a5a5232323f7f7f7f7a5a5a5a523232365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
652323232323f7f7f7f7f7f7f72323f7f7f7f72323232323232323232323a523232323232323232323232323232323232323232323f7f7f7a5a5a523f7f72365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6523232323f7f72323232323f723f7f7f723f72323232323232323232323f7f7f7f7f7f7f7f7f7232323232323232323232323232323232323a5a523f7f72365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65232323f7f723f7f723f7f7f7f7f7f7f723f72323232323232323232323f7f7f7f72323232323f72323232323232323232323232323232323a52323f7232365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6523232323232323232323232323f7232323f7232323232323232323232323232323f723232323f723232323232323232323232323232323232323f7f7232365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
652323232323232323232323232323230000000000230000000000000000000000000000000000000000000000002323f7f7f723232323232323f7f7f7232365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65232323232323232323232323232323f7f7f7f7f7f700f7000000232300230023002323f700f7f700000000f7f7f7f7f7f7f7f7f723f723f7f7f7f7f7232365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
652323000000000000f7f7f7f7f7f7f7f7f7f7f700f700f700f70023f7f700f7000000f7f7f7000000000000000000f7f7f7f7f7f7f7f7000000f7f7f7f72365
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000023000000000000000000000000000000000000000000000000000000f7f700000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000000000000f7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000007000000f7008525354747474747474747474747474747474747472535850000000000070000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000007000000f7008545554747474747474747474747474747474747474555850000000000070000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000007000000f7008545150535474747474747474747474747474725051555850000000000070000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000700000000008545151555474747474747474747474747474745151555850000000000070000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
651717171717171717171717171775000000f7008545151515053547474747474747474747250515151555850000000000752727272727272727272727272765
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002323000023
65050505050505050505050505050535000000008545151515155547474747474747474747451515151555850000000025050505050505050505050505050565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023000000
65151515151515151515151515151505350000000000000000004747474747474747474747470000000000000000002505151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023000000
65151515151515151515151515151515053500000000000000753737373737373737373737377500000000000000250515151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002323000000
65151515151515151515151515151515150505050505050505050505050505050505050505050505050505050505051515151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002300000003
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080008080000000000000000000000080808080808080804000000000000000808080808080800040000000000000000000000000000000000000000000000000102008080000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
42494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949324949493232494949494942555555555555555555555555554a4a4a550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
424949494949494949494949494949494949494949494949494932324a324a4a4a4a4a4a494949494a3249493249494932494932494949494949494949493242555555555555555555554a5555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232494949494949494a4a4a4a494949324a494949494949494932324a4a4a4a4a4a4a4a3232494a4a323249324932494932323249493232324949494949324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232494949494a4a4a4a323232324a32324a493249494949493232323232323232324a4a4a324a3232324949324949324a4a4932323232324a4a4949493242555555555555554a5555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232324a3232323232324a32324a323232324a4a32324a4a323232323232323232327f7f7f4a4a4a7f7f7f4949495a5a324a323232323232324a4a4a3249324255555555554a55555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232324a324a3232323232323232323232327f3232494a4a4a4a32323232323232323232324a4a3232324a5a4a4a4a324a32323232323232324a4a3232324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232324a3232323232323232323232323232324a3232494949494a4a323232323232323232324a4a3232324a4a4a7f4a7f7f7f7f7f3232323232324a4a4a324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232323232323232323232323232323232327f7f3232324a4949494949323232323232323232323232325a3232324a7f4a7f7f7f7f7f32323232324a32324a4255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232323232327f7f7f7f7f7f32323232327f324a4a3232324a3249494a4a3232323232323232323232323232324a4a4a3232327f7f7f7f7f7f4a4a3232324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232323232327f7f7f7f7f7f7f32327f7f4a7f32323232323232323232324a323232323232323232323232323232323232323232327f7f7f4a4a4a327f7f324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42323232327f7f32323232327f327f7f7f327f32323232323232323232327f7f7f7f7f7f7f7f7f323232323232323232323232323232323232324a327f7f324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232327f7f327f7f327f7f7f7f7f7f7f327f32323232323232323232327f7f7f7f32323232327f32323232323232323232323232323232324a32327f32324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42323232323232323232323232327f3232327f3232323232323232323232323232327f323232327f323232323232323232323232323232323232327f7f32324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232323232323232323232323232323232327f7f32323232327f32320000327f327f7f3232327f7f007f7f32323232327f7f7f323232323232327f7f7f32324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232323232323232323232323232327f7f7f7f7f7f007f3200003232003200323232327f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f327f327f7f7f7f7f32324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232320000000000007f7f7f7f7f7f7f7f7f7f7f007f7f7f007f00327f7f007f0000007f7f7f0000000000000000007f7f7f7f7f7f7f7f7f7f7f7f7f7f7f324255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
424844444444430000454444444332324544444444430000000000320000000000000000000000000000454444444443000045444444437f7f4544444444484255555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248000000004200000000000000000000007f00000000007373737373737300007373737373737300000000000000000000000000000000004200000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248000000007000000000000000000000007f00000000484544444444444300004544444444444348000000000000000000000000000000007000000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248000000007000000000000000000000007f00000000484274747474747474747474747474744248000000000000000000000000000000007000000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248717171717000000000000000000000007f00000000484274747474747474747474747474744248000000000000000000000000000000007072727272484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4244444444444348000000000000000000007f00000000484274747474747474747474747474744248000000000000000000000000000000484544444444444200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000004248000000000000000000007f00000000484274747474747474747474747474744248000000000000000000000000000000484200000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000004248000000000000000000007f00000000000074747474747474747474747474740000000000000000000000000000000000484200000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000007048000000000000000000007f00000000007474747474747474747474747474747400000000000000000000000000000000487000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200717171717048000000000000000000007f00000000007474747474747373737374747474747400000000000000000000000000000000487072727272004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248444444444444430000000000000000007f00000000007373737373734544444373737373737300000000000000000000000000000045444444444444484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248000000000000420000000000000000007f00000000004544444444444641414744444444444300000000000000000000000000000042000000000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248000000000000420000000000000000000000000000454641414141414141414141414141414743000000000000000000000000000042000000000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248000000000000700000004544444443000000000045464141414141414141414141414141414147430000000000454444444300000070000000000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248717171717171700000454641414147430000004546414141414141414141414141414141414141474300000045464141414743000070727272727272484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400001f01001000010000100001000010000100001000010000100001000010000100001000010000200001000010000100001000000000000000000000000f00000000000000000000000000000000000000
000a0000130701e040240302b0102b0002b0002a00025000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000c5700c6000c6000c6000c6000c6000c6000c6000c6000340003400044000440003500055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000364005640086300862007610056100461003610016100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c6100a610086100461001610016000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000013070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 20424344
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

