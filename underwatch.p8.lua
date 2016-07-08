pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--underwatch v0.12
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

	if temp_proj.pos.x > cam.pos.x and temp_proj.pos.x < cam.pos.x+128 and entity.isplayer then
		sfx(temp_proj.sfx)
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
	if entity.pos.x < 192 and entity.class != "support" and ((game.team == "team1" and #game.objective.team1_on_point == nil) or (game.team == "team2" and #game.objective.team2_on_point  == nil)) then
		entity.velocity.x += rnd(entity.speed)+rnd(entity.speed)
	elseif entity.pos.x > 312 and entity.class != "support" and ((game.team == "team1" and #game.objective.team1_on_point  == nil) or (game.team == "team2" and #game.objective.team2_on_point  == nil)) then
		entity.velocity.x -= rnd(entity.speed)+rnd(entity.speed)
	else
		if type(entity.target) then
			if entity.team == "team1" then
				preferredoffset = 15
			else
				preferredoffset = -15
			end

			if entity.target.pos.x > entity.pos.x+preferredoffset then
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
	if entity.canfly and rnd(10) < 5 and entity.pos.y > 8 then
		entity.velocity.y -= 0.5;
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
	otherteam = {}
	for key,otherentity in pairs(ai_entities) do
		if entity.class == "support" then
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
		if entity.class == "support" then
			if closest_target == nil or (val.hp/val.maxhp < closest_target.hp/closest_target.maxhp and val.class != "support") then
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
			if entity.shielded and entity.shields > 0 and bullet.damage > 0 then
				entity.shields -= bullet.damage
			else
				entity.hp -= bullet.damage
			end
			if bullet.damage > 0 then
				del(projectiles, bullet)
			end
		end
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
	if selectedchar.character == "sk8rboi" then
		print("passive area heal", cam.pos.x+46, cam.pos.y+113, drcol)
	end
	if selectedchar.character == "farout" then
		print("up - flight", cam.pos.x+46, cam.pos.y+113, drcol)
	end


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
	--area heal
	if entity.character == "sk8rboi" then
		for key,entity2 in pairs(ai_entities) do
			if abs(entity.pos.x - entity2.pos.x) <= 12 and abs(entity.pos.y - entity2.pos.y) <= 12 and entity2.team == entity.team and entity2 != entity then
				entity2.hp += 0.5
			end
		end
		for key,entity2 in pairs(player_entities) do
			if abs(entity.pos.x - entity2.pos.x) <= 12 and abs(entity.pos.y - entity2.pos.y) <= 12 and entity2.team == entity.team and entity2 != entity then
				entity2.hp += 0.5
			end
		end
	end
	--max hp
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
		if #game.objective.team1_on_point > 0 and #game.objective.team2_on_point <= 0 then
			game.objective.team1capturepercentage += game.objective.capturespeed*game.globalgamespeed*#game.objective.team1_on_point
			game.objective.team2capturepercentage -= game.objective.capturespeed*game.globalgamespeed*#game.objective.team1_on_point
		elseif #game.objective.team2_on_point > 0 and #game.objective.team1_on_point <= 0 then
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
			--game.ispaused = true
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
				--counters
				entity.shottimer -= 1
				entity.alternateshottimer -= 1
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
				if entity.pos.x > cam.pos.x and entity.pos.x < cam.pos.x+128 then
					draw_entity(entity)
					draw_health_bar(entity)
				end

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
					--entity.shielded = false
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
			if entity.pos.x > cam.pos.x and entity.pos.x < cam.pos.x+128 then
				draw_entity(entity)
			end
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
				if entity.canfly then
					entity.velocity.y -= 0.5;
				elseif entity.isjumping == false then
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
		firedelay = 7.5,
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
		sfx = 999,
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
		sfx = 999,
		mass = 2,
		maxage = 25,
		bounce = true,
		damage = 120,
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
		sfx = 999,
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
		sfx = 2,
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
		sfx = 999,
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
		sfx = 999,
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
		sfx = 999,
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
		sfx = 999,
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
		sfx = 999,
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
robogirl.hp = 100
robogirl.maxhp = 100
robogirl.shields = 400
robogirl.maxshields = 400
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
	walk = {43,43,43,43,43,43,43,44,44,44,44,44,44,44},
	jump = {43}
}
sk8rboi.primarydesc = "soundblast"
sk8rboi.primary = {}
	sk8rboi.primary[1] = {
		parent = "",
		sprite = 45,
		sfx = 999,
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
		sfx = 999,
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
		sfx = 999,
		mass = 0.1,
		maxage = 10,
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
cloud = {
	name = "cloud city",
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
00770000666666660767665000000000000000000000000007666650076666500777665000000000000000000bbbb33000007700000770000777665000000000
076677777ddd7ddd0766565077777500777777770077777777777550077755550500005000000000000000000777bb3077777670007665007666666500000000
07667666d7ddd7dd07666550675665507666766607766776777665500776665607766650000000000000d0000666b33076677660076666507666666500000000
06666667dd7ddd6d077666506565665066676667076766566767665007676656050000500000d0000000000007766b3066656660766776660776655000000000
07665656ddd6ddd60767665065665650665666560766765665665650076656560777665000000000000000000666653066557660666765650767665000000000
066655666ddd6ddd0766565065666550656665660766655665666550076665560500005000000000000000000767665065656650056656500766565000000000
05665555d6ddd6dd07666550575555505555555507775555555555000075555507676650000000d0000000000666655055556650005665000766655000000000
00550000dd6ddd6d077666500776665000000000077666500000000000000000050000500d000000000000000776665000005500000660000776665000000000
3b3b3b3344442444000bb3b33b3b30000ff424444444242007bbb330000000000ff44220000077700000000044442444444424200f4424440000000000000000
b333b33b424444440bb333333333b3000f4444444424424007bb3b30000000000f000020000000000000000042444442424444200f4444420000000000000000
323353354444444400b35335b23333300f444444444444200bbbb330000000000fff442000770000000007704442424444424240044242440000000000000000
23232323444444240b332323232b3b3004f444244444242007bbbb30000000000f000020000000000000000042442444424424200f44444400e0000000000000
424242424444444403b2424242424b330f444444444442400bbbb330000665000ff4f420000000000000000024222424242224200f4224240e88000000000000
4444444444442444b3324444444444b00f442444244424200bbb3b30066655500f0000200000000000000000222022222220220000404222e88220e000000000
4444424424444444032442444444424304f444444444442007bbb330666566500ff44220770077700000000020002002200020000000400200400e8200000000
244444444444444402444444244444400f4444444444242007bbb330665565550f000020000000000000000000000000000000000000000000f0004000000000
6500656666506665066665666656500656666656666656666565006505aaaa900eee88200666cc10760776600767766007677660767776600777767000000000
6500656500656506565000650656500656500650065006500065006556000065eee88882666cccc1776777760776777677677770776776700770006000000000
6500656500656506566650656506565656666650065006500066666565600656ee88822266ccc111776776770776767777677670076777600777676000000000
6500656500656506565000650656565656500650065006500065006560566506e0082002600c1001767777670777776776777760077777760700066000000000
6666656500656665066665650656666656500650065006666565006560055006e0082002600c1001777777670777776777777760767777760776776000000000
0000000aaa900000000000000000000000aaa9000000000000000000600000060e88822006ccc110777776770777767777777670767776760770006000000000
00000000a90000000000000000000000000a90000000000000000000560000650e88882006cccc10776677760076677677667700777777600776776000000000
00000000000000000000000000000000000000000000000000000000056666500082820000c1c100660007600000076066000000067777600770066000000000
000a0000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000cccccccc8888888899999999000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000
6595959595959595959595959595959595a59595959595959595950095959595959595959595959595959595959595959595959500a5a5a5a5a5959595a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65a5959595959595a5a5a59595959595a5a595959595959595000000a5a5a5a5a5a5a5a595959595a5009595009595950095950000959595a5a5959595a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65a5a59595959595a5a5a5a5a5959595a5a5a5a59595959595950000a5a5a5a5a5a5a5a5a50095a5a50000950095009500000000959595959595959595a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6500a5a595a5a5a5a5a5a500a5a5a5a500a5a5a5a59595959595950000000000000000a5a5a500a5a50000959500959500a5a5959595959595a5a595a5a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000a500a5a50000a5a50000a5a5a59500a5a5a5a5a5a500000000000000000000f7f7f7a5a5a5f7f7f7959595a5a500a595959595959595a5a5a5a5a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000a5a5a5a500000000000000a5a59595a595a59595a5a5a5a50000000000000000000000a5a5000000a5a5a5a5a500a5a5a5a5a595959595a5a5a5a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000a5a500000000000000000000000000a5a5000095959595a5a500000000000000000000a5a5000000a5a5a5f7a5f7f7f7f7f7a5a5959595a5a5a5a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000a50000000000000000000000000000a5a5a50000a5959595959500000000000000000000000000a5000000a5f7a5f7f7f7f7f7a5a5a5a5a5a5a5a5a565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000f7f7f7f7f7f70000000000f7a5a5a5000000a500959595a5000000000000000000000000000000a5a5a5000000f7f7f7f7a5a5a5a500000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000f7f7f7f7f7f7f70000f7f7f7f70000000000000000000000a500000000000000000000000000000000000000000000f7f7f7a5a5a500f7f70065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
651717171717171717171717171717f7f700f70000000000000000000000f7f7f7f7f7f7f7f7f700000000000000000000272727272727272727272727272765
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65050505050505050505050505053585f700f70000000000000000000000f7f7f7f70000000000f7000000000000000085250505050505050505050505050565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
651515151515151515151515151555850000e500000000e500000000000000000000f700000000000000e5000000000085451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65151515151515151515151515155585250505050505050535850000000000000000000000008525050505050505053585451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65151515151515151515151515155585d5b5b5b5b5b5b515c58500000000000000000000f70085d515b5b5b5b5b5b5c585451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65151515151515151515151515155585f7f7f7f700f7006500850000f7f700f7000000f7f7f7850065000000000000f785451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65151515151515151515151515155585000000000000006500850000000000000000000000008500650000000000000085451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65151515151515151515151515155585000000000000006500850000000000000000000000008500650000000000000085451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
651515151515151515151515151555850000f70000000065008500003737373737e5373700008500650000000000000085451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
651515151515151515151515151555850000f7000000004505053547250505050505053547250505550000000000000085451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
651515151515151515151515151555850000f700000000d5b5b5c547d5b5b5b5b5b5b5c547d5b5b5c50000000000000085451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
651515151515151515151515151555850000e50000000000000000474747474747474747470000000000000000e5000085451515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65151515151515151515151515151505050505350000000000000047474747474747474747000000000000002505050505151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5c5852535000000004747474747474747474700000000253585d5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000007000000f7008545550000000047474747474747474747000000004555850000000000070000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650000000000000000000000000007000000f7008545150535000047474747474747474747000025051555850000000000070000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
65000000000000000000000000000700000000008545151555e50047474747474747474747000045151555850000000000070000000000000000000000000065
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
651717171717171717171717171775000000f7008545151515053547474747474747474747250515151555850000000000752727272727272727272727272765
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002323000023
650505050505050505050505050505350000000085d5b5b5b5b5c547474747474747474747d5b5b5b5b5c5850000000025050505050505050505050505050565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023000000
65151515151515151515151515151505350000000000000000004747474747474747474747470000000000000000002505151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023000000
65151515151515151515151515151515053500e5000000e500753737373737373737373737377500000000e50000250515151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002323000000
65151515151515151515151515151515150505050505050505050505050505050505050505050505050505050505051515151515151515151515151515151565
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002300000003
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000080808080808080804000008080808000808080808080800040000080808000000000000000000000000080808080400000102008080000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
424949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949490049494900004949494949426d6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6d
42494949494949490049494949494949494949494949494949497f7f4a004a4a4a4a4a4a494949494a00494900494949004949004949494949494949494900426d7f00007f007f7f7f0000007f70007f007f7f7f00007f007f7f7f00007f007f7f7f00007f007f7f7f00007f007f7f7f00007f707f7f7f007f00007f007f7f6d
420049494949494900494949494949497f4a49494949494949497f7f4a4a4a4a4a4a4a4a0000494a4a00004900490049490000004949000000494949494900426d00000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000006d
424a49494949494900494949000000007f7f00497f49494949497f7f7f7f7f7f7f7f7f4a4a4a004a0000004949004949004a4a490000000000494a49494900426d00000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000006d
424949000000494900000000000000007f7f00007f7f4a4a494a7f7f7f4a4a4a4a4a4a4a4a4a004a7f7f7f494a4a4a4a004a0000000000000049494a004900426d00000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000006d
42494900000049000000000000000000000000007f7f4900004a4a4a4a4a7f7f7f7f7f7f4a4a00004a49004a49494a4a004a0000000000000049494a000000426d00000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000006d
4249490000000000000000000000000000000000007f494900494a4a4a7f7f7f7f7f7f7f7f7f4a4a4a4949494a4a7f4949000000000000000000494a4a4a00426d000000000000007f7f00007f707f7f7f00007f007f7f7f00007f007f7f7f00000000000000000000000000000000000000007000000000000000000000006d
4249490000000000000000000000000000007f7f00000000004949494a4a7f7f7f007f7f7f7f7f7f49494a490000494a4a004a00000000000000004a00004a426d00000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000006d
42494900000000007f7f7f0000000000004a7f494900000049000049494a4a7f7f7f7f7f7f4a7f4a4a4a4a4900004a4a4a4a4a00004a4a0000004a4a000000426d00000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000006d
42004a4a00007f7f007f7f7f000000000000004a4a0000004900000000494a7f7f7f7f7f7f4a49494a4a4a4a4a00000000000000000000004a4a4a00000000426d0000000000000000000000007000000000000000000000000000000000000000000000007f7f00000000007f7f0000000000707f000000000000000000006d
4200004a007f7f00000000007f000000004a0000000000000000490049494a7f7f7f7f7f7f494a4a004a4a49494a4a4a000000000000000000004a00000000426d000000000000000000000000700000000000000000000000000000000000007f00007f007f7f7f00007f007f7f7f00007f00707f000000000000000000006d
4200004a0000007f7f007f7f7f00007f7f007f0000000000000000494a4a7f7f7f7f0000000049490000004a4a4949004a4a4a0000000000004a0000000000426d71717171717171717171717170007f7f007f0000000000000000007f7f7f7f000000000000000000000000000000000000007072727272727272727272726d
42000000000000004a4a000000007f0000007f0000000000000000000000000000007f0000000000000000004a4a0049490000000000000000000000000000426d6b6a6a6a6a6a6a6a6a6a6a6a6c7f0000007f000000007f00007f007f7f0000000000000000000000000000000000000000006b6a6a6a6a6a6a6a6a6a6a6c6d
4200000000000000000000000000000000007f7f00000000007f000000000000007f7f00000000000000000000000000000000000000000000000000000000426d00000000000000000000000000000000007f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d
420000000000000000000000000000007f7f7f7f7f7f007f000000000000000000000000000000000000000000000000000000000000000000000000000000426d0000000000000000000000000000007f7f7f7f7f7f00000000000000000000000000000000000000000000000000000000000000000000000000000000006d
4200000000000000007f7f7f7f7f7f007f7f7f7f007f7f7f007f00007f7f007f00000000000000000000000000000000000000000000000000000000000000426d00000000007f7f007f7f7f00007f007f7f7f7f007f7f00000000000000007f00000000000000000000000000000000000000000000000000000000007f7f6d
42484444444c000000404444444c000040444444444c000000000000000000000000000000000000000040444444444c0000404444444c0000004044444448426d7f00007f007f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d
4248000000700000000000000000000000007f00000000004b73737373737400007473737373734b0000000000000000000000000000000000007000000048426d00000000000000000000000000000000000000000000007373737373737373737373737373737300000000000000000000000000000000000000000000006d
4248000000700000000000000000000000000000000000484544444444444c7474404444444444434800000000000000000000000000000000007000000048426d00000000000000000000000000000000007f7f0000006e6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6e000000000000000000000000000000000000000000006d
4248000000700000000000000000000000007f0000000048427474747474747474747474747474424800000000000000000000000000000000007000000048426d0000000000000000000000007f00007f007f7f0000006e747474747474747474747474747474746e000000000000000000000000000000000000000000006d
4248717171700000000000000000000000007f0000000048427474747474747474747474747474424800000000000000000000000000000000007072727248426d000000000000000000000000000000000000000000006e747474747474747474747474747474746e00000000000000000000000000000000000000007f7f6d
4244444444444c48000000000000000000007f0000000048427474747474747474747474747474424800000000000000000000000000000048404444444444426d000000000000000000000000000000000000000000006e747474747474747474747474747474746e0000000000000000000000000000007f00007f007f7f6d
420000000000704800000000000000000000000000000048477474747474744d4d747474747474464800000000000000000000000000000048700000000000426d000000000000007f7f00000000007f7f0000000000006e747474747474747474747474747474746e000000000000000000000000000000000000000000006d
4200000000007048000000004044444444444c00000000000074747474747474747474747474740000000000004044444444444c0000000048700000000000426d00007f00007f007f7f7f00007f007f7f007f7f0000006e747474747373737373737373747474746e000000000000000000000000000000000000000000006d
420000000000704800000000000000000000000000000000747474747474747474747474747474740000000000000000000000000000000048700000000000426d00000000000000000000000000000000007f7f0000006e7474746e6a6a6a6a6a6a6a6a6e7474746e000000000000000000000000000000000000000000006d
4200717171717048000000000000000000007f0000000000747474747474747474747474747474740000000000000000000000000000000048707272727200426d00000000007f7f0000000000000000007f7f000000006e7474746e74747474747474746e7474746e00000000000000000000000000000000000000007f7f6d
42484444444444444c0000000000000000007f00000000007373737373734b4b4b4b7373737373730000000000000000000000000000004044444444444448426d7f00007f007f7f0000000000000000007f7f000000006e7474746e74747474747474746e7474746e00000000000000000000000000007f7f00007f007f7f6d
4248000000000000700000000000000000007f0000000000454444444444444444444444444444430000000000000000000000000000007000000000000048426d000000000000000000000000000000000000000000006e7474746e74747474747474746e7474746e000000000000000000000000000000000000000000006d
424800000000000070000000000000000000000000000045464141414141414141414141414141474300000000000000000000000000007000000000000048426d000000000000000000000000000000000000000000006e747474747474747474747474747474746e000000000000000000000000000000000000000000006d
424800000000000070000000004544444443000000004546414141414141414141414141414141414743000000004544444443000000007000000000000048426d000000000000000000000000000000000000000000006e747474747474747474747474747474746e000000000000000000000000000000000000000000006d
4248717171717171700000004b47434e45464b00004546414141414141414141414141414141414141474300004b47434e45464b0000007072727272727248426d000000000000000000000000000000000000000000006e737373737373737373737373737373736e000000000000000000000000000000000000000000006d
474141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141466b6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6c
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

