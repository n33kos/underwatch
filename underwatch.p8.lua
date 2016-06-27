pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

--------------globals-----------------
---------------------------------------
ai_entities = {}
player_entities = {}
projectiles = {}

phys = {}
phys.drag = {1.1,1.1}
phys.bounce = {0.1,0.1}
phys.gravity = {0,-0.5}
phys.ground_height = 8
phys.time = 0

cam = {}
cam.pos = {}
cam.pos.x = 0
cam.pos.y = 0
cam.offset = {}
cam.offset.x = 64
cam.offset.y = 110
cam.followdistance = {}
cam.followdistance.x = 4
cam.followdistance.y = 2

currmap = {}
currmap.cel = {}
currmap.cel.x = 0
currmap.cel.y = 0
currmap.s = {}
currmap.s.x = 0
currmap.s.y = 0
currmap.dim = {}
currmap.dim.x = 64
currmap.dim.y = 16


--------------characters--------------
-------------------------------------

----------------soldier24-----------------
soldier24 = {}
soldier24.pos = {}
	soldier24.pos.x = 0
	soldier24.pos.y = 0
soldier24.sca = {}
	soldier24.sca.x = 8
	soldier24.sca.y = 8
soldier24.velocity = {}
	soldier24.velocity.x = rnd(2)
	soldier24.velocity.y = rnd(2)
soldier24.mass = 1
soldier24.speed = 0.1
soldier24.jumpheight = 5
soldier24.isjumping = true
soldier24.ismortal = true
soldier24.hp = 5
soldier24.maxhp = 5
soldier24.sprite = 0
soldier24.current_animation = "idle"
soldier24.animations = {}
	soldier24.animations.idle = {0}
	soldier24.animations.walk = {1,1,1,1,2,2,2,2}
	soldier24.animations.jump = {1}
soldier24.movement_behavior = "follow"
soldier24.attack_behavior = "primary"
soldier24.spriteflip = {}
	soldier24.spriteflip.x = true
	soldier24.spriteflip.y = false
soldier24.shottimer = 0
soldier24.projectile = {}
	soldier24.projectile.parent = ""
	soldier24.projectile.sprite = 3
	soldier24.projectile.mass = 0.2
	soldier24.projectile.maxage = 5
	soldier24.projectile.bounce = false
	soldier24.projectile.damage = 1
	soldier24.projectile.firedelay = 10 --draw frames between shots
	soldier24.projectile.velocity = {}
		soldier24.projectile.velocity.x = 10
		soldier24.projectile.velocity.y = 0
	soldier24.projectile.sca = {}
		soldier24.projectile.sca.x = 2
		soldier24.projectile.sca.y = 1
	soldier24.projectile.pixeloffset = {}
		soldier24.projectile.pixeloffset.x = 0
		soldier24.projectile.pixeloffset.y = 3
soldier24.alternateshottimer = 0
soldier24.alternate = {}
	soldier24.alternate.parent = ""
	soldier24.alternate.sprite = 4
	soldier24.alternate.mass = 0.5
	soldier24.alternate.maxage = 30
	soldier24.alternate.bounce = true
	soldier24.projectile.damage = 3
	soldier24.alternate.firedelay = 50 --draw frames between shots
	soldier24.alternate.velocity = {}
		soldier24.alternate.velocity.x = 10
		soldier24.alternate.velocity.y = -0.5
	soldier24.alternate.sca = {}
		soldier24.alternate.sca.x = 4
		soldier24.alternate.sca.y = 2
	soldier24.alternate.pixeloffset = {}
		soldier24.alternate.pixeloffset.x = 0
		soldier24.alternate.pixeloffset.y = 4
--------------------------filthmouse----------------------
filthmouse = {}
filthmouse.pos = {}
filthmouse.pos.x = 0
filthmouse.pos.y = 0
filthmouse.sca = {}
filthmouse.sca.x = 8
filthmouse.sca.y = 8
filthmouse.velocity = {}
filthmouse.velocity.x = rnd(2)
filthmouse.velocity.y = rnd(2)
filthmouse.mass = 1
filthmouse.speed = 0.1
filthmouse.jumpheight = 5
filthmouse.isjumping = true
filthmouse.ismortal = true
filthmouse.hp = 5
filthmouse.maxhp = 5
filthmouse.sprite = 32
filthmouse.current_animation = "idle"
filthmouse.animations = {}
	filthmouse.animations.idle = {32}
	filthmouse.animations.walk = {33,33,33,34,34,34}
	filthmouse.animations.jump = {33}
filthmouse.movement_behavior = "follow"
filthmouse.attack_behavior = "primary"
filthmouse.spriteflip = {}
filthmouse.spriteflip.x = true
filthmouse.spriteflip.y = false
filthmouse.shottimer = 0
filthmouse.projectile = {}
	filthmouse.projectile.parent = ""
	filthmouse.projectile.sprite = 35
	filthmouse.projectile.mass = 0.25
	filthmouse.projectile.maxage = 25
	filthmouse.projectile.bounce = true
	filthmouse.projectile.damage = 3
	filthmouse.projectile.firedelay = 25 --draw frames between shots
	filthmouse.projectile.velocity = {}
		filthmouse.projectile.velocity.x = 4
		filthmouse.projectile.velocity.y = -4
	filthmouse.projectile.sca = {}
		filthmouse.projectile.sca.x = 3
		filthmouse.projectile.sca.y = 3
	filthmouse.projectile.pixeloffset = {}
		filthmouse.projectile.pixeloffset.x = 0
		filthmouse.projectile.pixeloffset.y = 3
filthmouse.alternateshottimer = 0
filthmouse.alternate = {}
	filthmouse.alternate.parent = ""
	filthmouse.alternate.sprite = 35
	filthmouse.alternate.mass = 0.25
	filthmouse.alternate.maxage = 25
	filthmouse.alternate.bounce = true
	filthmouse.alternate.damage = 3
	filthmouse.alternate.firedelay = 25 --draw frames between shots
	filthmouse.alternate.velocity = {}
		filthmouse.alternate.velocity.x = 4
		filthmouse.alternate.velocity.y = -4
	filthmouse.alternate.sca = {}
		filthmouse.alternate.sca.x = 3
		filthmouse.alternate.sca.y = 3
	filthmouse.alternate.pixeloffset = {}
		filthmouse.alternate.pixeloffset.x = 0
		filthmouse.alternate.pixeloffset.y = 3
--------------------------rainheart----------------------
rainheart = {}
rainheart.pos = {}
rainheart.pos.x = 0
rainheart.pos.y = 0
rainheart.sca = {}
rainheart.sca.x = 8
rainheart.sca.y = 8
rainheart.velocity = {}
rainheart.velocity.x = rnd(2)
rainheart.velocity.y = rnd(2)
rainheart.mass = 2
rainheart.speed = 0.1
rainheart.jumpheight = 5
rainheart.isjumping = true
rainheart.ismortal = true
rainheart.hp = 20
rainheart.maxhp = 5
rainheart.sprite = 32
rainheart.current_animation = "idle"
rainheart.animations = {}
	rainheart.animations.idle = {16}
	rainheart.animations.walk = {17,17,17,18,18,18}
	rainheart.animations.jump = {17}
rainheart.movement_behavior = "follow"
rainheart.attack_behavior = "alternate"
rainheart.spriteflip = {}
rainheart.spriteflip.x = true
rainheart.spriteflip.y = false
rainheart.shottimer = 0
rainheart.projectile = {}
	rainheart.projectile.parent = ""
	rainheart.projectile.sprite = 19
	rainheart.projectile.mass = 0.25
	rainheart.projectile.maxage = 2
	rainheart.projectile.bounce = false
	rainheart.projectile.damage = 2
	rainheart.projectile.firedelay = 4 --draw frames between shots
	rainheart.projectile.velocity = {}
		rainheart.projectile.velocity.x = 1
		rainheart.projectile.velocity.y = 0
	rainheart.projectile.sca = {}
		rainheart.projectile.sca.x = 6
		rainheart.projectile.sca.y = 6
	rainheart.projectile.pixeloffset = {}
		rainheart.projectile.pixeloffset.x = 0
		rainheart.projectile.pixeloffset.y = 0
rainheart.alternateshottimer = 0
rainheart.alternate = {}
	rainheart.alternate.parent = ""
	rainheart.alternate.sprite = 20
	rainheart.alternate.mass = 1
	rainheart.alternate.maxage = 1
	rainheart.alternate.bounce = false
	rainheart.alternate.damage = 0
	rainheart.alternate.firedelay = 1 --draw frames between shots
	rainheart.alternate.velocity = {}
		rainheart.alternate.velocity.x = 0
		rainheart.alternate.velocity.y = 0
	rainheart.alternate.sca = {}
		rainheart.alternate.sca.x = 1
		rainheart.alternate.sca.y = 8
	rainheart.alternate.pixeloffset = {}
		rainheart.alternate.pixeloffset.x = 1
		rainheart.alternate.pixeloffset.y = 0
--------------------------spiderlady----------------------
spiderlady = {}
spiderlady.pos = {}
spiderlady.pos.x = 0
spiderlady.pos.y = 0
spiderlady.sca = {}
spiderlady.sca.x = 8
spiderlady.sca.y = 8
spiderlady.velocity = {}
spiderlady.velocity.x = rnd(2)
spiderlady.velocity.y = rnd(2)
spiderlady.mass = 1
spiderlady.speed = 0.2
spiderlady.jumpheight = 7.5
spiderlady.isjumping = true
spiderlady.ismortal = true
spiderlady.hp = 3
spiderlady.maxhp = 3
spiderlady.sprite = 5
spiderlady.current_animation = "idle"
spiderlady.animations = {}
	spiderlady.animations.idle = {5}
	spiderlady.animations.walk = {6,6,6,7,7,7}
	spiderlady.animations.jump = {6}
spiderlady.movement_behavior = "follow"
spiderlady.attack_behavior = "primary"
spiderlady.spriteflip = {}
spiderlady.spriteflip.x = true
spiderlady.spriteflip.y = false
spiderlady.shottimer = 0
spiderlady.projectile = {}
	spiderlady.projectile.parent = ""
	spiderlady.projectile.sprite = 8
	spiderlady.projectile.mass = 0.1
	spiderlady.projectile.maxage = 50
	spiderlady.projectile.bounce = false
	spiderlady.projectile.damage = 10
	spiderlady.projectile.firedelay = 20 --draw frames between shots
	spiderlady.projectile.velocity = {}
		spiderlady.projectile.velocity.x = 10
		spiderlady.projectile.velocity.y = 0
	spiderlady.projectile.sca = {}
		spiderlady.projectile.sca.x = 8
		spiderlady.projectile.sca.y = 1
	spiderlady.projectile.pixeloffset = {}
		spiderlady.projectile.pixeloffset.x = 0
		spiderlady.projectile.pixeloffset.y = 2
spiderlady.alternateshottimer = 0
spiderlady.alternate = {}
	spiderlady.alternate.parent = ""
	spiderlady.alternate.sprite = 9
	spiderlady.alternate.mass = 0.1
	spiderlady.alternate.maxage = 10
	spiderlady.alternate.bounce = true
	spiderlady.alternate.damage = 2
	spiderlady.alternate.firedelay = 10 --draw frames between shots
	spiderlady.alternate.velocity = {}
		spiderlady.alternate.velocity.x = 5
		spiderlady.alternate.velocity.y = -2.5
	spiderlady.alternate.sca = {}
		spiderlady.alternate.sca.x = 4
		spiderlady.alternate.sca.y = 2
	spiderlady.alternate.pixeloffset = {}
		spiderlady.alternate.pixeloffset.x = 0
		spiderlady.alternate.pixeloffset.y = 0



--copy tables, yum.
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

-------------------entities
function make_player()
	temp_entity = copy(rainheart)
	temp_entity.projectile.parent = "team1"
	temp_entity.alternate.parent = "team1"
	temp_entity.pos.x = rnd(256)
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(player_entities, temp_entity)
end

function make_ai()
	temp_entity = copy(filthmouse)
	temp_entity.projectile.parent = "team1"
	temp_entity.alternate.parent = "team1"
	temp_entity.pos.x = rnd(256)
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(ai_entities, temp_entity)
	temp_entity = copy(spiderlady)
	temp_entity.projectile.parent = "team1"
	temp_entity.alternate.parent = "team1"
	temp_entity.pos.x = rnd(256)
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(ai_entities, temp_entity)
	temp_entity = copy(soldier24)
	temp_entity.projectile.parent = "team1"
	temp_entity.alternate.parent = "team1"
	temp_entity.pos.x = rnd(256)
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(ai_entities, temp_entity)

	temp_entity = copy(soldier24)
	temp_entity.projectile.parent = "team2"
	temp_entity.alternate.parent = "team2"
	temp_entity.pos.x = rnd(256)+256
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(ai_entities, temp_entity)
	temp_entity = copy(rainheart)
	temp_entity.projectile.parent = "team2"
	temp_entity.alternate.parent = "team2"
	temp_entity.pos.x = rnd(256)+256
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(ai_entities, temp_entity)
	temp_entity = copy(spiderlady)
	temp_entity.projectile.parent = "team2"
	temp_entity.alternate.parent = "team2"
	temp_entity.pos.x = rnd(256)+256
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(ai_entities, temp_entity)
	temp_entity = copy(filthmouse)
	temp_entity.projectile.parent = "team2"
	temp_entity.alternate.parent = "team2"
	temp_entity.pos.x = rnd(256)+256
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(ai_entities, temp_entity)
end

function make_projectile(sprite, mass, bounce, damage, sca, pos, velocity, maxage, direction, parent)
	proj = {}
	proj.age = 0
	proj.maxage = maxage
	proj.damage = damage
	proj.parent = parent
	proj.pos = {}
		proj.pos.x = pos.x
		proj.pos.y = pos.y
	proj.sca = {}
		proj.sca.x = sca.x
		proj.sca.y = sca.y
	proj.velocity = {}
		if direction == true then
			proj.velocity.x = velocity.x*-1
		else
			proj.velocity.x = velocity.x
		end
		proj.velocity.y = velocity.y
	proj.mass = mass
	proj.bounce = bounce
	proj.sprite = sprite
	proj.spriteflip = {}
		proj.spriteflip.x = direction
		proj.spriteflip.y = false

	add(projectiles, proj)
end


function ai_movement_behavior(entity)
	if entity.movement_behavior == "random" then
		if rnd(2) > 1 then
			entity.velocity.x += rnd(entity.speed)
		else
			entity.velocity.x -= rnd(entity.speed)
		end

		if rnd(10) < 0.25 and entity.isjumping != true then
			entity.velocity.y -= rnd(entity.jumpheight)
		end
		entity.current_animation = "walk"
	elseif entity.movement_behavior == "follow" then
		if player_entities[1] then
			if player_entities[1].pos.x > entity.pos.x then
				entity.velocity.x += rnd(entity.speed)+rnd(entity.speed)
			else
				entity.velocity.x -= rnd(entity.speed)+rnd(entity.speed)
			end
			if player_entities[1].pos.y < entity.pos.y then
				if rnd(10) < 1 and entity.isjumping != true then
					entity.velocity.y -= rnd(entity.jumpheight)
				end
			end
		end
		entity.current_animation = "walk"
	else
		entity.current_animation = "idle"
	end

	if entity.velocity.x > 0 then
		entity.spriteflip.x = false
	elseif entity.velocity.x < 0 then
		entity.spriteflip.x = true
	end
end

function ai_attack_behavior(entity)
	if entity.attack_behavior == "primary" then
		--counter
		entity.shottimer -= 1

		--adjust bullet start location
		adjustedpos = {}
		if entity.spriteflip.x then
			adjustedpos.x = entity.pos.x-entity.sca.x-entity.projectile.pixeloffset.x+1
		else
			adjustedpos.x = entity.pos.x+entity.sca.x+entity.projectile.pixeloffset.x
		end
		adjustedpos.y = entity.pos.y+entity.projectile.pixeloffset.y

		if entity.shottimer <= 0 then
			entity.shottimer = entity.projectile.firedelay
			make_projectile(entity.projectile.sprite, entity.projectile.mass, entity.projectile.bounce, entity.projectile.damage, entity.projectile.sca, adjustedpos, entity.projectile.velocity, entity.projectile.maxage, entity.spriteflip.x, entity.projectile.parent)
		end
	elseif entity.attack_behavior == "alternate" then
		--counter
		entity.alternateshottimer -= 1

		--adjust bullet start location
		adjustedpos = {}
		if entity.spriteflip.x then
			adjustedpos.x = entity.pos.x-entity.sca.x-entity.alternate.pixeloffset.x+1
		else
			adjustedpos.x = entity.pos.x+entity.sca.x+entity.alternate.pixeloffset.x
		end
		adjustedpos.y = entity.pos.y+entity.alternate.pixeloffset.y

		if entity.alternateshottimer <= 0 then
			entity.alternateshottimer = entity.alternate.firedelay
			make_projectile(entity.alternate.sprite, entity.alternate.mass, entity.alternate.bounce, entity.alternate.damage, entity.alternate.sca, adjustedpos, entity.alternate.velocity, entity.alternate.maxage, entity.spriteflip.x, entity.alternate.parent)
		end

		--probably a better way to do this
		if entity.alternate.damage == 0 then
			entity.ismortal = false
		end
	end
end

function assess_hp(entity, table)
	if entity.hp <= 0 then
		del(table, entity)
	end
end

------------physics
function apply_gravity(entity)
	entity.velocity.y = entity.velocity.y-phys.gravity[2]*entity.mass
end

function apply_velocity(entity)
	entity.pos.x = entity.pos.x+entity.velocity.x
	entity.pos.y = entity.pos.y+entity.velocity.y
end

function apply_drag(entity)
	entity.velocity.x /= phys.drag[1]
	entity.velocity.y /= phys.drag[2]
end

function apply_solid_body_collision(entity)
	top = {flr((entity.pos.x+(entity.sca.x/2))/8), flr(entity.pos.y/8)}
	bottom = {top[1], flr((entity.pos.y+(entity.sca.y-1))/8)}
	left = {flr(entity.pos.x/8), flr((entity.pos.y+(entity.sca.y/2))/8)}
	right = {flr((entity.pos.x+(entity.sca.x-1))/8), left[2]}
	
	--bottom
	val = mget(bottom[1]+currmap.cel.x, bottom[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.y = 0
		entity.mass = 0
		entity.isjumping = false
		entity.pos.y = (bottom[2]-1)*8 -- make sure the entity stays within bounds
		return
	else
		entity.isjumping = true
		entity.mass = 1
	end

	--left
	val = mget(left[1]+currmap.cel.x, left[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= phys.bounce[1]
		entity.pos.x = (left[1]+1)*8 -- make sure the entity stays within bounds
		return
	end

	--right
	val = mget(right[1]+currmap.cel.x, right[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= phys.bounce[1]
		entity.pos.x = (right[1]-1)*8 -- make sure the entity stays within bounds
		return
	end

	--top
	val = mget(top[1]+currmap.cel.x, top[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.y *= -1
		entity.pos.y = (top[2]+1)*8 -- make sure the entity stays within bounds
		return
	end

end

function projectile_collision(entity, parenttype)
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
		if intersect and bullet.parent != entity.projectile.parent then
			if entity.ismortal then
				entity.hp -= bullet.damage
			end
			del(projectiles, bullet)
		end
	end
end

-------------drawing
function draw_entity(entity)
	spr(entity.sprite, entity.pos.x, entity.pos.y, entity.sca.x/8, entity.sca.y/8, entity.spriteflip.x, entity.spriteflip.y)
end

function draw_map()
	map(currmap.cel.x, currmap.cel.y, currmap.s.x, currmap.s.y, currmap.dim.x, currmap.dim.y)
end

function move_camera()
	camera(cam.pos.x,cam.pos.y)
	if player_entities[1] then
		cam.pos.x = cam.pos.x + (player_entities[1].pos.x - (cam.pos.x+cam.offset.x))/cam.followdistance.x
		cam.pos.y = cam.pos.y + (player_entities[1].pos.y - (cam.pos.y+cam.offset.y))/cam.followdistance.y
	end
end

function set_animation_frame(entity)
	if entity.isjumping and entity.velocity.y < 0 then
		entity.current_animation = "jump"
	elseif entity.velocity.x > 0.2 or entity.velocity.x < -0.2 then
		entity.current_animation = "walk"
	else
		entity.current_animation = "idle"
	end


	if entity.current_animation == "idle" then
		entity.sprite = entity.animations.idle[phys.time % #entity.animations.idle+1]
	end
	if entity.current_animation == "walk" then
		entity.sprite = entity.animations.walk[phys.time % #entity.animations.walk+1]
	end
	if entity.current_animation == "jump" then
		entity.sprite = entity.animations.jump[phys.time % #entity.animations.jump+1]
	end
end

-----------pico functions--------------
---------------------------------------
function _init()
	cls()
	make_player()
	make_ai()
end

function _update()
	--ai entities
	for key,entity in pairs(ai_entities) do
		assess_hp(entity, ai_entities)
		ai_movement_behavior(entity)
		ai_attack_behavior(entity)
		apply_gravity(entity)
		apply_velocity(entity)
		apply_solid_body_collision(entity)
		apply_drag(entity)
		projectile_collision(entity)
		set_animation_frame(entity)
	end

	--player entities
	for key,entity in pairs(player_entities) do
		assess_hp(entity, player_entities)
		apply_gravity(entity)
		apply_velocity(entity)
		apply_solid_body_collision(entity)
		apply_drag(entity)
		projectile_collision(entity)
		set_animation_frame(entity)
	end

	--projectiles
	for key,entity in pairs(projectiles) do
		apply_gravity(entity)
		apply_velocity(entity)
		if entity.bounce then
			apply_solid_body_collision(entity)
		end
		entity.age += 1
		if entity.age >= entity.maxage then
			del(projectiles, entity)
		end
	end

end

function _draw()
	cls()
	phys.time += 1

	-----------------------player input----------------------
	---------------------------------------------------------
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
	end
	if btn(4) then
		--one
		for key,entity in pairs(player_entities) do
			--counter
			entity.shottimer -= 1
			
			--adjust bullet start location
			adjustedpos = {}
			if entity.spriteflip.x then
				adjustedpos.x = entity.pos.x-entity.sca.x-entity.projectile.pixeloffset.x+1
			else
				adjustedpos.x = entity.pos.x+entity.sca.x+entity.projectile.pixeloffset.x
			end
			adjustedpos.y = entity.pos.y+entity.projectile.pixeloffset.y

			--main fire
			if entity.shottimer <= 0 then
				entity.shottimer = entity.projectile.firedelay
				make_projectile(entity.projectile.sprite, entity.projectile.mass, entity.projectile.bounce, entity.projectile.damage, entity.projectile.sca, adjustedpos, entity.projectile.velocity, entity.projectile.maxage, entity.spriteflip.x, entity.projectile.parent)
			end
			
		end
	end
	if btn(5) then
		for key,entity in pairs(player_entities) do
			--counter
			entity.alternateshottimer -= 1

			--adjust bullet start location
			adjustedpos = {}
			if entity.spriteflip.x then
				adjustedpos.x = entity.pos.x-entity.alternate.pixeloffset.x+1
			else
				adjustedpos.x = entity.pos.x+entity.sca.x+entity.alternate.pixeloffset.x
			end
			adjustedpos.y = entity.pos.y+entity.projectile.pixeloffset.y

			--alternate fire
			if entity.alternateshottimer <= 0 then
				entity.alternateshottimer = entity.alternate.firedelay
				make_projectile(entity.alternate.sprite, entity.alternate.mass, entity.alternate.bounce, entity.projectile.damage, entity.alternate.sca, adjustedpos, entity.alternate.velocity, entity.alternate.maxage, entity.spriteflip.x, entity.alternate.parent)
			end

			--probably a better way
			if entity.alternate.damage == 0 then
				entity.ismortal = false
			end
		end
	else
		for key,entity in pairs(player_entities) do
			--probably a better way
			if entity.alternate.damage == 0 then
				entity.ismortal = true
			end
		end
	end

	--camera
	move_camera()

	--map
	draw_map()

	--ai entities
	for key,entity in pairs(ai_entities) do
		draw_entity(entity)
	end

	--player entities
	for key,entity in pairs(player_entities) do
		draw_entity(entity)
	end

	--projectiles
	for key,entity in pairs(projectiles) do
		draw_entity(entity)
	end
	
end


__gfx__
066f0000066f0000066f000095500000ac660000225500002255000022550000777777660cc00000000000000000000000000000000000000000000000000000
06f8000006f8000006f8000000000000915500002258000022580000225800000000000050050000000000000000000000000000000000000000000000000000
01150000011500000115000000000000000000002e6666662e6666662e6666660000000000000000000000000000000000000000000000000000000000000000
0cc666660cc666660cc6666600000000000000002e5650002e5650002e5650000000000000000000000000000000000000000000000000000000000000000000
0c1156000c1156000c1156000000000000000000055e0000055e0000055e00000000000000000000000000000000000000000000000000000000000000000000
055500000555000005550000000000000000000006e6000006e6000006e600000000000000000000000000000000000000000000000000000000000000000000
05050000050500000505000000000000000000000505000005050000050500000000000000000000000000000000000000000000000000000000000000000000
06060000600600000660000000000000000000000505000050050000055000000000000000000000000000000000000000000000000000000000000000000000
00000600000006000000060006600000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066600000666000006660000665000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06065a0606065a0606065a0600656500c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06665566066655660666556606505000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05666665056666650566666565000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005f560f005f560f005f560f50000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00056500000565000005650000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050500005005000005500000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009a9000009a9000009a90009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000af400000af400000af40098900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
060fff00060fff00060fff0009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005a555a005a555a005a555a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005fff50005fff50005fff5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06099900060999000609990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090700000907000009070000000000006886000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070700007007000007700000000000055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3b3b334444444411111111dddddddd888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b333b33b4444444411111111ddddddddeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353353354444444411111111dddddddde22ee2e20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
434343434444444411111111dddddddd2dde2d2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444411111111ddddddddddd2dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444411111111dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444411111111dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444411111111dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002323000023
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023000000
0000000000000000f30000000000000000000000000000000000000000000000f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000023000000
000000f3f3f3f3f3f3f3f300f3f300f300f300f3f3f3f3f300f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002323000000
f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f300000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002300000003
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232343434343434323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232343434343432323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323030303232323232323232323232323232323232323232323232323232323232323232323232323232323232323434343434323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323234343434343232323232323232323232323232323232323232323232323234343300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323230303232323232323230303030323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232343432323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323232323232323232323232323232323232323232323432323232323232323432323232323232323234343432323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323230303030323232323232323232323232323234343432323232323232343434323232323232323434343432323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303030303030303030303030303030303030343434343434343434343434343434343434343434343434343434343434343300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f0000000000000000000000003f3f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f003f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f00003f00003f3f3f3f000000003f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f000000000000003f00000000003f003f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f0000000000000000000000000000003f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f0000000000000000000000000000003f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000003f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
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
00 41424344

