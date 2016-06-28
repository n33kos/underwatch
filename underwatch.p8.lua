pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

-----------------------------------helper functions--------------------------------
-----------------------------------------------------------------------------------
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

function cleanup(entity, table)
	cleanuplimit = 2047
	for k, v in pairs(entity) do
		if type(v) == 'table' then
			for k2, v2 in pairs(v) do
				if type(v2) == "number" and (v2 > cleanuplimit or v2 < -cleanuplimit) then
					del(table, entity)
				end
			end
		else
			if type(v) == "number" and (v > cleanuplimit or v < -cleanuplimit) then
				del(table, entity)
			end
		end
	end
end

---------------------------------------globals-------------------------------------
-----------------------------------------------------------------------------------
ai_entities = {}
player_entities = {}
projectiles = {}

phys = {}
phys.drag = {1.05,1.05}
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

game = {}
game.score = {}
game.score.team1 = 0
game.score.team2 = 0

---------------------------------------characters---------------------------------
-----------------------------------------------------------------------------------
char_template = {}
char_template = {}
char_template.pos = {}
	char_template.pos.x = 0
	char_template.pos.y = 0
char_template.sca = {}
	char_template.sca.x = 8
	char_template.sca.y = 8
char_template.velocity = {}
	char_template.velocity.x = rnd(2)
	char_template.velocity.y = rnd(2)
char_template.mass = 1
char_template.speed = 0.05
char_template.jumpheight = 5
char_template.isjumping = true
char_template.ismortal = true
char_template.shielded = false
char_template.hp = 5
char_template.maxhp = 5
char_template.sprite = 0
char_template.team = "none"
char_template.current_animation = "idle"
char_template.movement_behavior = "follow"
char_template.attack_behavior = "cycle"
char_template.spriteflip = {}
	char_template.spriteflip.x = true
	char_template.spriteflip.y = false
char_template.shottimer = 0
char_template.primary = {}
char_template.alternateshottimer = 0
char_template.alternate = {}
char_template.spriteflip = {}
	char_template.spriteflip.x = true
	char_template.spriteflip.y = false

----------------soldier24-----------------
soldier24 = copy(char_template)
soldier24.character = "soldier24"
soldier24.animations = {}
	soldier24.animations.idle = {0}
	soldier24.animations.walk = {1,1,1,1,2,2,2,2}
	soldier24.animations.jump = {1}
soldier24.primary = {}
	soldier24.primary[1] = {}
		soldier24.primary[1].sprite = 3
		soldier24.primary[1].mass = 0.2
		soldier24.primary[1].maxage = 5
		soldier24.primary[1].bounce = false
		soldier24.primary[1].damage = 1
		soldier24.primary[1].firedelay = 10 --draw frames between shots
		soldier24.primary[1].velocity = {}
			soldier24.primary[1].velocity.x = 10
			soldier24.primary[1].velocity.y = 0
		soldier24.primary[1].sca = {}
			soldier24.primary[1].sca.x = 2
			soldier24.primary[1].sca.y = 1
		soldier24.primary[1].pixeloffset = {}
			soldier24.primary[1].pixeloffset.x = 0
			soldier24.primary[1].pixeloffset.y = 3
soldier24.alternate = {}
	soldier24.alternate[1] = {}
		soldier24.alternate[1].sprite = 4
		soldier24.alternate[1].mass = 0.5
		soldier24.alternate[1].maxage = 30
		soldier24.alternate[1].bounce = true
		soldier24.alternate[1].damage = 3
		soldier24.alternate[1].firedelay = 50 --draw frames between shots
		soldier24.alternate[1].velocity = {}
			soldier24.alternate[1].velocity.x = 10
			soldier24.alternate[1].velocity.y = -0.5
		soldier24.alternate[1].sca = {}
			soldier24.alternate[1].sca.x = 4
			soldier24.alternate[1].sca.y = 2
		soldier24.alternate[1].pixeloffset = {}
			soldier24.alternate[1].pixeloffset.x = 0
			soldier24.alternate[1].pixeloffset.y = 4

---------------filthmouse--------------
filthmouse = copy(char_template)
filthmouse.character = "filthmouse"
filthmouse.animations = {}
	filthmouse.animations.idle = {32}
	filthmouse.animations.walk = {33,33,33,34,34,34}
	filthmouse.animations.jump = {33}
filthmouse.primary = {}
	filthmouse.primary[1] = {}
		filthmouse.primary[1].parent = ""
		filthmouse.primary[1].sprite = 35
		filthmouse.primary[1].mass = 0.25
		filthmouse.primary[1].maxage = 25
		filthmouse.primary[1].bounce = true
		filthmouse.primary[1].damage = 3
		filthmouse.primary[1].firedelay = 25 --draw frames between shots
		filthmouse.primary[1].velocity = {}
			filthmouse.primary[1].velocity.x = 4
			filthmouse.primary[1].velocity.y = -4
		filthmouse.primary[1].sca = {}
			filthmouse.primary[1].sca.x = 3
			filthmouse.primary[1].sca.y = 3
		filthmouse.primary[1].pixeloffset = {}
			filthmouse.primary[1].pixeloffset.x = 0
			filthmouse.primary[1].pixeloffset.y = 3
filthmouse.alternate = {}
	filthmouse.alternate[1] = {}
		filthmouse.alternate[1].parent = ""
		filthmouse.alternate[1].sprite = 36
		filthmouse.alternate[1].mass = 2
		filthmouse.alternate[1].maxage = 25
		filthmouse.alternate[1].bounce = true
		filthmouse.alternate[1].damage = 5
		filthmouse.alternate[1].firedelay = 50 --draw frames between shots
		filthmouse.alternate[1].velocity = {}
			filthmouse.alternate[1].velocity.x = 0.5
			filthmouse.alternate[1].velocity.y = 0
		filthmouse.alternate[1].sca = {}
			filthmouse.alternate[1].sca.x = 6
			filthmouse.alternate[1].sca.y = 2
		filthmouse.alternate[1].pixeloffset = {}
			filthmouse.alternate[1].pixeloffset.x = 0
			filthmouse.alternate[1].pixeloffset.y = 3

------------------rainhorse----------------------
rainhorse = copy(char_template)
rainhorse.character = "rainhorse"
rainhorse.mass = 2
rainhorse.speed *= 0.5
rainhorse.hp = 15
rainhorse.maxhp = 15
rainhorse.animations = {}
	rainhorse.animations.idle = {16}
	rainhorse.animations.walk = {17,17,17,18,18,18}
	rainhorse.animations.jump = {17}
rainhorse.primary = {}
	rainhorse.primary[1] = {}
		rainhorse.primary[1].parent = ""
		rainhorse.primary[1].sprite = 19
		rainhorse.primary[1].mass = 0.25
		rainhorse.primary[1].maxage = 2
		rainhorse.primary[1].bounce = false
		rainhorse.primary[1].damage = 1
		rainhorse.primary[1].firedelay = 15 --draw frames between shots
		rainhorse.primary[1].velocity = {}
			rainhorse.primary[1].velocity.x = 0
			rainhorse.primary[1].velocity.y = 0
		rainhorse.primary[1].sca = {}
			rainhorse.primary[1].sca.x = 6
			rainhorse.primary[1].sca.y = 6
		rainhorse.primary[1].pixeloffset = {}
			rainhorse.primary[1].pixeloffset.x = 0
			rainhorse.primary[1].pixeloffset.y = 0
rainhorse.alternate = {}
	rainhorse.alternate[1] = {}
		rainhorse.alternate[1].parent = ""
		rainhorse.alternate[1].sprite = 20
		rainhorse.alternate[1].mass = 1
		rainhorse.alternate[1].maxage = 2
		rainhorse.alternate[1].bounce = false
		rainhorse.alternate[1].damage = 0
		rainhorse.alternate[1].firedelay = 0 --draw frames between shots
		rainhorse.alternate[1].velocity = {}
			rainhorse.alternate[1].velocity.x = 0
			rainhorse.alternate[1].velocity.y = 0
		rainhorse.alternate[1].sca = {}
			rainhorse.alternate[1].sca.x = 1
			rainhorse.alternate[1].sca.y = 8
		rainhorse.alternate[1].pixeloffset = {}
			rainhorse.alternate[1].pixeloffset.x = 0
			rainhorse.alternate[1].pixeloffset.y = 0

--------------------------spiderlady----------------------
spiderlady = copy(char_template)
spiderlady.character = "spiderlady"
spiderlady.speed *= 1.5
spiderlady.jumpheight = 7.5
spiderlady.hp = 3
spiderlady.maxhp = 3
spiderlady.animations = {}
	spiderlady.animations.idle = {5}
	spiderlady.animations.walk = {6,6,6,7,7,7}
	spiderlady.animations.jump = {6}
spiderlady.primary = {}
	spiderlady.primary[1] = {}
		spiderlady.primary[1].parent = ""
		spiderlady.primary[1].sprite = 8
		spiderlady.primary[1].mass = 0.1
		spiderlady.primary[1].maxage = 50
		spiderlady.primary[1].bounce = false
		spiderlady.primary[1].damage = 10
		spiderlady.primary[1].firedelay = 60 --draw frames between shots
		spiderlady.primary[1].velocity = {}
			spiderlady.primary[1].velocity.x = 10
			spiderlady.primary[1].velocity.y = 0
		spiderlady.primary[1].sca = {}
			spiderlady.primary[1].sca.x = 8
			spiderlady.primary[1].sca.y = 1
		spiderlady.primary[1].pixeloffset = {}
			spiderlady.primary[1].pixeloffset.x = 0
			spiderlady.primary[1].pixeloffset.y = 2
spiderlady.alternate = {}
	spiderlady.alternate[1] = {}
		spiderlady.alternate[1].parent = ""
		spiderlady.alternate[1].sprite = 9
		spiderlady.alternate[1].mass = 0.1
		spiderlady.alternate[1].maxage = 10
		spiderlady.alternate[1].bounce = true
		spiderlady.alternate[1].damage = 2
		spiderlady.alternate[1].firedelay = 40 --draw frames between shots
		spiderlady.alternate[1].velocity = {}
			spiderlady.alternate[1].velocity.x = 5
			spiderlady.alternate[1].velocity.y = -2.5
		spiderlady.alternate[1].sca = {}
			spiderlady.alternate[1].sca.x = 4
			spiderlady.alternate[1].sca.y = 2
		spiderlady.alternate[1].pixeloffset = {}
			spiderlady.alternate[1].pixeloffset.x = 0
			spiderlady.alternate[1].pixeloffset.y = 0

--------------------------grace----------------------
grace = copy(char_template)
grace.character = "grace"
grace.speed *= 1.5
grace.jumpheight = 5
grace.hp = 5
grace.maxhp = 5
grace.mass = 0.1
grace.animations = {}
	grace.animations.idle = {21}
	grace.animations.walk = {22,22,22,22,23,23,23,23}
	grace.animations.jump = {22}
grace.primary = {}
	grace.primary[1] = {}
		grace.primary[1].parent = ""
		grace.primary[1].sprite = 24
		grace.primary[1].mass = 0.1
		grace.primary[1].maxage = 2
		grace.primary[1].bounce = false
		grace.primary[1].damage = -1
		grace.primary[1].firedelay = 1 --draw frames between shots
		grace.primary[1].velocity = {}
			grace.primary[1].velocity.x = 4
			grace.primary[1].velocity.y = 0
		grace.primary[1].sca = {}
			grace.primary[1].sca.x = 8
			grace.primary[1].sca.y = 3
		grace.primary[1].pixeloffset = {}
			grace.primary[1].pixeloffset.x = 2
			grace.primary[1].pixeloffset.y = 1
grace.alternate = {}
	grace.alternate[1] = {}
		grace.alternate[1].parent = ""
		grace.alternate[1].sprite = 25
		grace.alternate[1].mass = 0.1
		grace.alternate[1].maxage = 10
		grace.alternate[1].bounce = false
		grace.alternate[1].damage = 1
		grace.alternate[1].firedelay = 15 --draw frames between shots
		grace.alternate[1].velocity = {}
			grace.alternate[1].velocity.x = 5
			grace.alternate[1].velocity.y = 0
		grace.alternate[1].sca = {}
			grace.alternate[1].sca.x = 2
			grace.alternate[1].sca.y = 1
		grace.alternate[1].pixeloffset = {}
			grace.alternate[1].pixeloffset.x = 0
			grace.alternate[1].pixeloffset.y = 2
		
--------------------------bowman----------------------
bowman = copy(char_template)
bowman.character = "bowman"
bowman.jumpheight = 5
bowman.hp = 5
bowman.maxhp = 5
bowman.mass = 0.1
bowman.animations = {}
	bowman.animations.idle = {37}
	bowman.animations.walk = {38,38,38,38,39,39,39,39}
	bowman.animations.jump = {38}
bowman.primary = {}
	bowman.primary[1] = {}
		bowman.primary[1].parent = ""
		bowman.primary[1].sprite = 40
		bowman.primary[1].mass = 1
		bowman.primary[1].maxage = 40
		bowman.primary[1].bounce = false
		bowman.primary[1].damage = 5
		bowman.primary[1].firedelay = 40 --draw frames between shots
		bowman.primary[1].velocity = {}
			bowman.primary[1].velocity.x = 5
			bowman.primary[1].velocity.y = -4
		bowman.primary[1].sca = {}
			bowman.primary[1].sca.x = 5
			bowman.primary[1].sca.y = 1
		bowman.primary[1].pixeloffset = {}
			bowman.primary[1].pixeloffset.x = 0
			bowman.primary[1].pixeloffset.y = 3
bowman.alternate = {}
	bowman.alternate[1] = {}
		bowman.alternate[1].parent = ""
		bowman.alternate[1].sprite = 40
		bowman.alternate[1].mass = 1
		bowman.alternate[1].maxage = 40
		bowman.alternate[1].bounce = false
		bowman.alternate[1].damage = 5
		bowman.alternate[1].firedelay = 60 --draw frames between shots
		bowman.alternate[1].velocity = {}
			bowman.alternate[1].velocity.x = 5
			bowman.alternate[1].velocity.y = -4
		bowman.alternate[1].sca = {}
			bowman.alternate[1].sca.x = 5
			bowman.alternate[1].sca.y = 1
		bowman.alternate[1].pixeloffset = {}
			bowman.alternate[1].pixeloffset.x = 0
			bowman.alternate[1].pixeloffset.y = 3
	bowman.alternate[2] = {}
		bowman.alternate[2].parent = ""
		bowman.alternate[2].sprite = 40
		bowman.alternate[2].mass = 1
		bowman.alternate[2].maxage = 40
		bowman.alternate[2].bounce = false
		bowman.alternate[2].damage = 5
		bowman.alternate[2].firedelay = 60 --draw frames between shots
		bowman.alternate[2].velocity = {}
			bowman.alternate[2].velocity.x = 5
			bowman.alternate[2].velocity.y = -3
		bowman.alternate[2].sca = {}
			bowman.alternate[2].sca.x = 5
			bowman.alternate[2].sca.y = 1
		bowman.alternate[2].pixeloffset = {}
			bowman.alternate[2].pixeloffset.x = 0
			bowman.alternate[2].pixeloffset.y = 3

all_characters = {soldier24, filthmouse, rainhorse, spiderlady, grace, bowman}

------------------------------------init functions-----------------------------------
-----------------------------------------------------------------------------------
function make_player()
	temp_entity = copy(bowman)
	temp_entity.team = "team1"
	for key,val in pairs(temp_entity.primary) do
		val.parent = "team1"
	end
	for key,val in pairs(temp_entity.alternate) do
		val.parent = "team1"
	end
	temp_entity.pos.x = rnd(256)
	temp_entity.pos.y = rnd(128) - phys.ground_height
	add(player_entities, temp_entity)
	cam.target = temp_entity
end

function make_ai()
	--team 1
	for i=1,#all_characters do
		temp_entity = copy(all_characters[i])
		temp_entity.team = "team1"
		for key,val in pairs(temp_entity.primary) do
			val.parent = "team1"
		end
		for key,val in pairs(temp_entity.alternate) do
			val.parent = "team1"
		end
		temp_entity.pos.x = rnd(256)
		temp_entity.pos.y = rnd(128) - phys.ground_height
		add(ai_entities, temp_entity)
	end
	--team 2
	for i=1,#all_characters do
		temp_entity = copy(all_characters[i])
		temp_entity.team = "team2"
		for key,val in pairs(temp_entity.primary) do
			val.parent = "team2"
		end
		for key,val in pairs(temp_entity.alternate) do
			val.parent = "team2"
		end
		temp_entity.pos.x = rnd(256)+256
		temp_entity.pos.y = rnd(128) - phys.ground_height
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

	add(projectiles, temp_proj)
end


--------------------------------------ai functions-------------------------------------
----------------------------------------------------------------------------------------

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

		if entity.target then
			if entity.target.pos.x > entity.pos.x then
				entity.velocity.x += rnd(entity.speed)+rnd(entity.speed)
			else
				entity.velocity.x -= rnd(entity.speed)+rnd(entity.speed)
			end
			if rnd(10) < 2 and entity.isjumping != true then
				entity.velocity.y -= rnd(entity.jumpheight)
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

		if entity.shottimer <= 0 then
			for key,val in pairs(entity.primary) do
				entity.shottimer = val.firedelay
				make_projectile(entity, val)
			end
		end
	elseif entity.attack_behavior == "alternate" then
		--counter
		entity.alternateshottimer -= 1

		if entity.alternateshottimer <= 0 then
			for key,val in pairs(entity.alternate) do
				entity.alternateshottimer = val.firedelay
				make_projectile(entity, val)
			end
			if entity.character == "rainhorse" then
				entity.shielded = true
			end
		end

	elseif entity.attack_behavior == "cycle" then
		--counter
		entity.shottimer -= 1
		entity.alternateshottimer -= 1
		if rnd(10) < 5 then
			if entity.shottimer <= 0 and phys.time%2 == 0 then
				for key,val in pairs(entity.primary) do
					entity.shottimer = val.firedelay
					make_projectile(entity, val)
				end
			end
			if entity.alternateshottimer <= 0 and phys.time%2 == 1 then
				for key,val in pairs(entity.alternate) do
					entity.alternateshottimer = val.firedelay
					make_projectile(entity, val)
				end
				if entity.character == "rainhorse" then
					entity.shielded = true
				end
			end
		end


	end
end

function ai_get_target(entity)
	--then ai
	otherteam = {}
	for key,otherentity in pairs(ai_entities) do
		if otherentity.team != entity.team then
			add(otherteam, otherentity)
		end
	end
	return otherteam[flr(rnd(#otherteam))+1]
end

function assess_hp(entity, table)
	if entity.hp <= 0 then
		--temporary fun forever fight!----------------------
		team = entity.team
		tmp = copy(all_characters[flr(rnd(#all_characters))+1])
		if team == "team2" then
			tmp.pos.x = 400
		else
			tmp.pos.x = 12
		end
		tmp.pos.y = 0
		tmp.team = team
		for key,projectile in pairs(tmp.primary) do
			projectile.parent = team
		end
		for key,projectile in pairs(tmp.alternate) do
			projectile.parent = team
		end
		
		add(ai_entities, tmp)
		------------------------------------
		if team == "team1" then
			game.score.team2 += 1
		else
			game.score.team1 += 1
		end
		del(table, entity)
	elseif entity.hp > entity.maxhp then
		entity.hp = entity.maxhp
	end
end

------------------------------------physics functions-----------------------------------
----------------------------------------------------------------------------------------
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
		entity.velocity.x *= -phys.bounce[1]
		entity.pos.x = (left[1]+1)*8 -- make sure the entity stays within bounds
		return
	end

	--right
	val = mget(right[1]+currmap.cel.x, right[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= -phys.bounce[1]
		entity.pos.x = (right[1]-1)*8 -- make sure the entity stays within bounds
		return
	end

	--top
	val = mget(top[1]+currmap.cel.x, top[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.y *= -phys.bounce[2]
		entity.pos.y = (top[2]+1)*8 -- make sure the entity stays within bounds
		return
	end

end

function projectile_collision(entity)
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
		if intersect and entity.ismortal and entity.shielded == false and bullet.damage != nil and ((bullet.damage > 0 and bullet.parent != entity.team) or (bullet.damage < 0 and bullet.parent == entity.team)) then
			entity.hp -= bullet.damage
			del(projectiles, bullet)
		end
	end
end

------------------------------------drawing functions-----------------------------------
----------------------------------------------------------------------------------------
function draw_entity(entity)
	spr(entity.sprite, entity.pos.x, entity.pos.y, entity.sca.x/8, entity.sca.y/8, entity.spriteflip.x, entity.spriteflip.y)
end

function draw_map()
	map(currmap.cel.x, currmap.cel.y, currmap.s.x, currmap.s.y, currmap.dim.x, currmap.dim.y)
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

	--assign animation frame to draw sprite. animation frames use phys.time modulus the length of the animation
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

function draw_health_bar(entity)
	if entity.team == "team1" then
		colors = {1,12}
	else
		colors = {2,8}
	end
	line(entity.pos.x, entity.pos.y-7, entity.pos.x+entity.sca.x, entity.pos.y-7, colors[1])
	line(entity.pos.x, entity.pos.y-7, entity.pos.x+((entity.hp/entity.maxhp)*entity.sca.x), entity.pos.y-7, colors[2])
end

----------------------------------------execution---------------------------------------
----------------------------------------------------------------------------------------
function _init()
	cls()
	make_player()
	make_ai()
end

function _update()
	--ai entities
	for key,entity in pairs(ai_entities) do
		cleanup(entity, ai_entities)
		assess_hp(entity, ai_entities)
		entity.target = ai_get_target(entity)
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
		cleanup(entity, player_entities)
		assess_hp(entity, player_entities)
		entity.target = ai_get_target(entity)
		apply_gravity(entity)
		apply_velocity(entity)
		apply_solid_body_collision(entity)
		apply_drag(entity)
		projectile_collision(entity)
		set_animation_frame(entity)
	end

	--projectiles
	for key,entity in pairs(projectiles) do
		cleanup(entity, projectiles)
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

	--camera
	if #player_entities > 0 then
		cam.target = player_entities[1]
	elseif #ai_entities > 0 then
		cam.target = ai_entities[2]
	end
	move_camera()

	--gui
	print(game.score.team1.."-"..game.score.team2, cam.pos.x, cam.pos.y)

	--map
	draw_map()

	--ai entities
	for key,entity in pairs(ai_entities) do
		draw_entity(entity)
		draw_health_bar(entity)

		if entity.character == "rainhorse" then
			entity.shielded = false
		end
	end

	--player entities
	for key,entity in pairs(player_entities) do
		draw_entity(entity)
		draw_health_bar(entity)

		--resets
		if entity.character == "rainhorse" then
			entity.shielded = false
		end
	end

	--projectiles
	for key,entity in pairs(projectiles) do
		draw_entity(entity)
	end


	-------------------------------------player feedback------------------------------------
	----------------------------------------------------------------------------------------
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
		--take control of ai character
		if #player_entities == 0 and #ai_entities > 0 then
			add(player_entities, ai_entities[1])
			del(ai_entities, ai_entities[1])
		end

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
	end
	if btn(5) then
		for key,entity in pairs(player_entities) do
			--counter
			entity.alternateshottimer -= 1

			--alternate fire
			if entity.alternateshottimer <= 0 then
				for key,val in pairs(entity.alternate) do
					entity.alternateshottimer = val.firedelay
					make_projectile(entity, val)
				end

				if entity.character == "rainhorse" then
					entity.shielded = true
				end
			end
		end
	end
end


__gfx__
066f0000066f0000066f000095500000c1660000225500002255000022550000777777660cc00000000000000000000000000000000000000000000000000000
06f8000006f8000006f8000000000000c15500002258000022580000225800000000000050050000000000000000000000000000000000000000000000000000
01150000011500000115000000000000000000002e6666662e6666662e6666660000000000000000000000000000000000000000000000000000000000000000
0cc666660cc666660cc6666600000000000000002e5650002e5650002e5650000000000000000000000000000000000000000000000000000000000000000000
0c1156000c1156000c1156000000000000000000055e0000055e0000055e00000000000000000000000000000000000000000000000000000000000000000000
055500000555000005550000000000000000000006e6000006e6000006e600000000000000000000000000000000000000000000000000000000000000000000
05050000050500000505000000000000000000000505000005050000050500000000000000000000000000000000000000000000000000000000000000000000
06060000600600000660000000000000000000000505000050050000055000000000000000000000000000000000000000000000000000000000000000000000
00000600000006000000060006600000c0000000770a9a00770a9a00000a9a0009000000a9000000000000000000000000000000000000000000000000000000
00066600000666000006660000665000c0000000a779af00a779af007709af00aa99999900000000000000000000000000000000000000000000000000000000
06065a0606065a0606065a0600656500c00000000a7afe050a7afe05a77afe050900000000000000000000000000000000000000000000000000000000000000
06665566066655660666556606505000c000000000a6665000a666500a7666500000000000000000000000000000000000000000000000000000000000000000
05666665056666650566666565000000c0000000000775700007757000a775700000000000000000000000000000000000000000000000000000000000000000
005f560f005f560f005f560f50000000c00000000006560000065600000656000000000000000000000000000000000000000000000000000000000000000000
00056500000565000005650000000000c00000000005060000050600000506000000000000000000000000000000000000000000000000000000000000000000
00050500005005000005500000000000c00000000006060000606000006060000000000000000000000000000000000000000000000000000000000000000000
00a9a90000a9a90000a9a900090000000880000005a5500005a5500005a550005666700056667000000000000000000000000000000000000000000000000000
000aff00000aff00000aff009890000055550000005ff060005ff060005ff0600000000000000000000000000000000000000000000000000000000000000000
060ff700060ff700060ff7000900000000000000075fe006075fe006075fe0060000000056667000000000000000000000000000000000000000000000000000
005a555a005a555a005a555a000000000000000006c1fff606c1fff606c1fff60000000000000000000000000000000000000000000000000000000000000000
005ff500005ff500005ff500000000000000000006cc500606cc500606cc50060000000056667000000000000000000000000000000000000000000000000000
06099900060999000609990000000000000000000611100606111006061110060000000000000000000000000000000000000000000000000000000000000000
00090700000907000009070000000000000000000010106000101060001010600000000000000000000000000000000000000000000000000000000000000000
00070700007007000007700000000000000000000050500005005000005500000000000000000000000000000000000000000000000000000000000000000000
3b3b3b334444444400000000dddddddd888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b333b33b4444444400000000ddddddddeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
353353354444444400000000dddddddde22ee2e20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
434343434444444400000000dddddddd2dde2d2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444400000000ddddddddddd2dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444400000000dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444400000000dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444400000000dddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
3132323232323232323232323232323232323232323232323232323232323232323232323232343434323232323232323432323232323232323234343432323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323232323232323232323232323230303030323232323232323232323232323234343434343232323232343434323232323232323434343432323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

