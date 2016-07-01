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

function cleanup(entity)
	cleanuplimit = 2047
	for k, v in pairs(entity) do
		if type(v) == 'table' then
			for k2, v2 in pairs(v) do
				if type(v2) == "number" and (v2 > cleanuplimit or v2 < -cleanuplimit) then
					entity.hp = 0
				end
			end
		else
			if type(v) == "number" and (v > cleanuplimit or v < -cleanuplimit) then
				entity.hp = 0
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
phys.gravity = {0,-0.35}
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
currmap.dim.y = 32

game = {}
game.score = {}
game.score.team1 = 0
game.score.team2 = 0

---------------------------------------characters---------------------------------
-----------------------------------------------------------------------------------
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
char_template.onLadder = false
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
soldier24 = {}
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
filthmouse = {}
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
		filthmouse.primary[1].mass = 1
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
rainhorse = {}
rainhorse = copy(char_template)
rainhorse.character = "rainhorse"
rainhorse.mass = 1
rainhorse.speed *= 0.75
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
		rainhorse.primary[1].bounce = true
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
		rainhorse.alternate[1].bounce = true
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
spiderlady = {}
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
grace = {}
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
bowman = {}
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

--------------------------harvester----------------------
harvester = {}
harvester = copy(char_template)
harvester.character = "harvester"
harvester.jumpheight = 5
harvester.hp = 5
harvester.maxhp = 5
harvester.mass = 0.1
harvester.animations = {}
	harvester.animations.idle = {10}
	harvester.animations.walk = {11,11,11,11,12,12,12,12}
	harvester.animations.jump = {11}
harvester.primary = {}
	harvester.primary[1] = {}
		harvester.primary[1].parent = ""
		harvester.primary[1].sprite = 13
		harvester.primary[1].mass = 1
		harvester.primary[1].maxage = 5
		harvester.primary[1].bounce = false
		harvester.primary[1].damage = 1
		harvester.primary[1].firedelay = 15 --draw frames between shots
		harvester.primary[1].velocity = {}
			harvester.primary[1].velocity.x = 5
			harvester.primary[1].velocity.y = 0
		harvester.primary[1].sca = {}
			harvester.primary[1].sca.x = 1
			harvester.primary[1].sca.y = 1
		harvester.primary[1].pixeloffset = {}
			harvester.primary[1].pixeloffset.x = 0
			harvester.primary[1].pixeloffset.y = 3
	harvester.primary[2] = {}
		harvester.primary[2].parent = ""
		harvester.primary[2].sprite = 13
		harvester.primary[2].mass = 1
		harvester.primary[2].maxage = 5
		harvester.primary[2].bounce = false
		harvester.primary[2].damage = 1
		harvester.primary[2].firedelay = 15 --draw frames between shots
		harvester.primary[2].velocity = {}
			harvester.primary[2].velocity.x = 5
			harvester.primary[2].velocity.y = -2
		harvester.primary[2].sca = {}
			harvester.primary[2].sca.x = 1
			harvester.primary[2].sca.y = 1
		harvester.primary[2].pixeloffset = {}
			harvester.primary[2].pixeloffset.x = 0
			harvester.primary[2].pixeloffset.y = 3
	harvester.primary[3] = {}
		harvester.primary[3].parent = ""
		harvester.primary[3].sprite = 13
		harvester.primary[3].mass = 1
		harvester.primary[3].maxage = 5
		harvester.primary[3].bounce = false
		harvester.primary[3].damage = 1
		harvester.primary[3].firedelay = 10 --draw frames between shots
		harvester.primary[3].velocity = {}
			harvester.primary[3].velocity.x = 5
			harvester.primary[3].velocity.y = -1
		harvester.primary[3].sca = {}
			harvester.primary[3].sca.x = 1
			harvester.primary[3].sca.y = 1
		harvester.primary[3].pixeloffset = {}
			harvester.primary[3].pixeloffset.x = 0
			harvester.primary[3].pixeloffset.y = 3
harvester.alternate = {}
	harvester.alternate[1] = {}
		harvester.alternate[1].parent = ""
		harvester.alternate[1].sprite = 14
		harvester.alternate[1].mass = 2
		harvester.alternate[1].maxage = 100
		harvester.alternate[1].bounce = false
		harvester.alternate[1].damage = 0
		harvester.alternate[1].firedelay = 60 --draw frames between shots
		harvester.alternate[1].velocity = {}
			harvester.alternate[1].velocity.x = 0
			harvester.alternate[1].velocity.y = 0
		harvester.alternate[1].sca = {}
			harvester.alternate[1].sca.x = 8
			harvester.alternate[1].sca.y = 4
		harvester.alternate[1].pixeloffset = {}
			harvester.alternate[1].pixeloffset.x = -8
			harvester.alternate[1].pixeloffset.y = 4
	harvester.alternate[2] = {}
		harvester.alternate[2].parent = ""
		harvester.alternate[2].sprite = 14
		harvester.alternate[2].mass = 2
		harvester.alternate[2].maxage = 100
		harvester.alternate[2].bounce = false
		harvester.alternate[2].damage = 0
		harvester.alternate[2].firedelay = 60 --draw frames between shots
		harvester.alternate[2].velocity = {}
			harvester.alternate[2].velocity.x = 0
			harvester.alternate[2].velocity.y = 0
		harvester.alternate[2].sca = {}
			harvester.alternate[2].sca.x = 8
			harvester.alternate[2].sca.y = 4
		harvester.alternate[2].pixeloffset = {}
			harvester.alternate[2].pixeloffset.x = 56
			harvester.alternate[2].pixeloffset.y = 4

------------------robogirl----------------------
robogirl = {}
robogirl = copy(char_template)
robogirl.character = "robogirl"
robogirl.mass = 1
robogirl.hp = 10
robogirl.maxhp = 10
robogirl.animations = {}
	robogirl.animations.idle = {26}
	robogirl.animations.walk = {27,27,27,28,28,28}
	robogirl.animations.jump = {27}
robogirl.primary = {}
	robogirl.primary[1] = {}
		robogirl.primary[1].parent = ""
		robogirl.primary[1].sprite = 29
		robogirl.primary[1].mass = 1
		robogirl.primary[1].maxage = 5
		robogirl.primary[1].bounce = false
		robogirl.primary[1].damage = 1
		robogirl.primary[1].firedelay = 15 --draw frames between shots
		robogirl.primary[1].velocity = {}
			robogirl.primary[1].velocity.x = 5
			robogirl.primary[1].velocity.y = 0
		robogirl.primary[1].sca = {}
			robogirl.primary[1].sca.x = 1
			robogirl.primary[1].sca.y = 1
		robogirl.primary[1].pixeloffset = {}
			robogirl.primary[1].pixeloffset.x = 0
			robogirl.primary[1].pixeloffset.y = 3
	robogirl.primary[2] = {}
		robogirl.primary[2].parent = ""
		robogirl.primary[2].sprite = 29
		robogirl.primary[2].mass = 1
		robogirl.primary[2].maxage = 5
		robogirl.primary[2].bounce = false
		robogirl.primary[2].damage = 1
		robogirl.primary[2].firedelay = 15 --draw frames between shots
		robogirl.primary[2].velocity = {}
			robogirl.primary[2].velocity.x = 5
			robogirl.primary[2].velocity.y = -2
		robogirl.primary[2].sca = {}
			robogirl.primary[2].sca.x = 1
			robogirl.primary[2].sca.y = 1
		robogirl.primary[2].pixeloffset = {}
			robogirl.primary[2].pixeloffset.x = 0
			robogirl.primary[2].pixeloffset.y = 3
	robogirl.primary[3] = {}
		robogirl.primary[3].parent = ""
		robogirl.primary[3].sprite = 29
		robogirl.primary[3].mass = 1
		robogirl.primary[3].maxage = 5
		robogirl.primary[3].bounce = false
		robogirl.primary[3].damage = 1
		robogirl.primary[3].firedelay = 10 --draw frames between shots
		robogirl.primary[3].velocity = {}
			robogirl.primary[3].velocity.x = 5
			robogirl.primary[3].velocity.y = -1
		robogirl.primary[3].sca = {}
			robogirl.primary[3].sca.x = 1
			robogirl.primary[3].sca.y = 1
		robogirl.primary[3].pixeloffset = {}
			robogirl.primary[3].pixeloffset.x = 0
			robogirl.primary[3].pixeloffset.y = 3
robogirl.alternate = {}
	robogirl.alternate[1] = {}
		robogirl.alternate[1].parent = ""
		robogirl.alternate[1].sprite = 30
		robogirl.alternate[1].mass = 1
		robogirl.alternate[1].maxage = 2
		robogirl.alternate[1].bounce = false
		robogirl.alternate[1].damage = 0
		robogirl.alternate[1].firedelay = 0 --draw frames between shots
		robogirl.alternate[1].velocity = {}
			robogirl.alternate[1].velocity.x = 0
			robogirl.alternate[1].velocity.y = 0
		robogirl.alternate[1].sca = {}
			robogirl.alternate[1].sca.x = 8
			robogirl.alternate[1].sca.y = 5
		robogirl.alternate[1].pixeloffset = {}
			robogirl.alternate[1].pixeloffset.x = 0
			robogirl.alternate[1].pixeloffset.y = 0


all_characters = {soldier24, filthmouse, rainhorse, spiderlady, grace, bowman, harvester, robogirl}

------------------------------------init functions-----------------------------------
-----------------------------------------------------------------------------------
function make_player()
	temp_entity = copy(robogirl)
	temp_entity.team = "team1"
	for key,val in pairs(temp_entity.primary) do
		val.parent = "team1"
	end
	for key,val in pairs(temp_entity.alternate) do
		val.parent = "team1"
	end
	spawn = find_spawn_point(temp_entity)
	temp_entity.pos.x = spawn[1]
	temp_entity.pos.y = spawn[2]
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
		spawn = find_spawn_point(temp_entity)
		temp_entity.pos.x = spawn[1]
		temp_entity.pos.y = spawn[2]
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
	temp_proj.velocity.x += entity.velocity.x
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

function find_spawn_point(entity)
	points = {}
	for i=0,currmap.dim.x do
		for j=0,currmap.dim.y do
			val = {i*8,j*8}
			cell = mget(val[1]/8,val[2]/8)
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
			if entity.isjumping != true and (rnd(10) < 1 or (entity.velocity.x < 0.2 and entity.velocity.x > -0.2)) then
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
			if entity.character == "rainhorse" or entity.character == "robogirl" then
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
				if entity.character == "rainhorse" or entity.character == "robogirl" then
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
		tmp.team = team
		spawn = find_spawn_point(tmp)
		tmp.pos.x = spawn[1]
		tmp.pos.y = spawn[2]
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

function apply_entity_map_collision(entity)
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
		entity.pos.y = flr((bottom[2]-1)*8) -- make sure the entity stays within bounds
		return
	else
		entity.isjumping = true
		entity.mass = 1
	end

	--top
	val = mget(top[1]+currmap.cel.x, top[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.y *= -phys.bounce[2]
		entity.pos.y = flr((top[2]+1)*8) -- make sure the entity stays within bounds
	end

	--left
	val = mget(left[1]+currmap.cel.x, left[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= -phys.bounce[1]
		entity.pos.x = flr((left[1]+1)*8) -- make sure the entity stays within bounds
	end

	--right
	val = mget(right[1]+currmap.cel.x, right[2]+currmap.cel.y)
	if fget(val, 7) == true then
		entity.velocity.x *= -phys.bounce[1]
		entity.pos.x = flr((right[1]-1)*8) -- make sure the entity stays within bounds
	end


end


function apply_projectile_map_collision(bullet)

	if bullet.bounce then
		top = {flr((bullet.pos.x+(bullet.sca.x/2))/8), flr(bullet.pos.y/8)}
		bottom = {top[1], flr((bullet.pos.y+(bullet.sca.y-1))/8)}
		left = {flr(bullet.pos.x/8), flr((bullet.pos.y+(bullet.sca.y/2))/8)}
		right = {flr((bullet.pos.x+(bullet.sca.x-1))/8), left[2]}
		
		--bottom
		val = mget(bottom[1]+currmap.cel.x, bottom[2]+currmap.cel.y)
		if fget(val, 7) == true then
			if bullet.bounce then
				bullet.velocity.y *= -phys.bounce[1]
			end
			bullet.pos.y = (bottom[2]-1)*8 -- make sure the bullet stays within bounds
		end

		--left
		val = mget(left[1]+currmap.cel.x, left[2]+currmap.cel.y)
		if fget(val, 7) == true then
			bullet.pos.x = (left[1]+1)*8 -- make sure the bullet stays within bounds
		end

		--right
		val = mget(right[1]+currmap.cel.x, right[2]+currmap.cel.y)
		if fget(val, 7) == true then
			if bullet.bounce then
				bullet.velocity.x *= -phys.bounce[1]
			end
			bullet.pos.x = (right[1]-1)*8 -- make sure the bullet stays within bounds
		end

		--top
		val = mget(top[1]+currmap.cel.x, top[2]+currmap.cel.y)
		if fget(val, 7) == true then
			if bullet.bounce then
				bullet.velocity.y *= -phys.bounce[2]
			end
			bullet.pos.y = (top[2]+1)*8 -- make sure the bullet stays within bounds
		end
	else
		val = mget(flr(bullet.pos.x/8), flr(bullet.pos.y/8))
		if fget(val, 7) == true then
			del(projectiles, bullet)
			return
		end
	end

end

function apply_ladder_collision(entity)
	val = mget(flr((entity.pos.x+entity.sca.x/2)/8), flr((entity.pos.y+entity.sca.y/2)/8))
	if fget(val, 6) == true then
		entity.onLadder = true
		entity.velocity.y -= 0.5
		entity.isjumping = false
	else
		entity.onLadder = false
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
		cleanup(entity)
		assess_hp(entity, ai_entities)
		entity.target = ai_get_target(entity)
		ai_movement_behavior(entity)
		ai_attack_behavior(entity)
		if entity.onLadder == false then apply_gravity(entity) end
		apply_velocity(entity)
		apply_drag(entity)
		apply_entity_map_collision(entity)
		apply_ladder_collision(entity)
		projectile_collision(entity)
		set_animation_frame(entity)
	end

	--player entities
	for key,entity in pairs(player_entities) do
		cleanup(entity)
		assess_hp(entity, player_entities)
		entity.target = ai_get_target(entity)
		if entity.onLadder == false then apply_gravity(entity) end
		apply_velocity(entity)
		apply_drag(entity)
		apply_entity_map_collision(entity)
		apply_ladder_collision(entity)
		projectile_collision(entity)
		set_animation_frame(entity)
	end

	--projectiles
	for key,entity in pairs(projectiles) do
		cleanup(entity)
		apply_gravity(entity)
		apply_velocity(entity)
		apply_projectile_map_collision(entity)
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

	--map
	draw_map()

	--ai entities
	for key,entity in pairs(ai_entities) do
		draw_entity(entity)
		draw_health_bar(entity)

		if entity.character == "rainhorse" or entity.character == "robogirl" then
			entity.shielded = false
		end
	end

	--player entities
	for key,entity in pairs(player_entities) do
		draw_entity(entity)
		draw_health_bar(entity)

		--resets
		if entity.character == "rainhorse" or entity.character == "robogirl" then
			entity.shielded = false
		end
	end

	--projectiles
	for key,entity in pairs(projectiles) do
		draw_entity(entity)
	end

	--gui
	print(game.score.team1.."-"..game.score.team2, cam.pos.x, cam.pos.y)
	if player_entities[1] then
		print(player_entities[1].character, cam.pos.x+50, cam.pos.y)
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

				if entity.character == "rainhorse" or entity.character == "robogirl" then
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
end


__gfx__
066f0000066f0000066f000095500000c1660000225500002255000022550000777777660cc00000005550000055500000555000200000000800800800000000
06f8000006f8000006f8000000000000c15500002258000022580000225800000000000050050000005570000055700000557000000000002802802800000000
01150000011500000115000000000000000000002e6666662e6666662e666666000000000000000005557f5505557f5505557f55000000008028028200000000
0cc666660cc666660cc6666600000000000000002e5650002e5650002e5650000000000000000000056550000565500005655000000000002222222200000000
0c1156000c1156000c1156000000000000000000055e0000055e0000055e0000000000000000000005666f5505666f5505666f55000000000000000000000000
055500000555000005550000000000000000000006e6000006e6000006e600000000000000000000051115005511150055111500000000000000000000000000
05050000050500000505000000000000000000000505000005050000050500000000000000000000051510005510100055101000000000000000000000000000
06060000600600000660000000000000000000000505000050050000055000000000000000000000051510005100100050110000000000000000000000000000
00000600000006000000060006600000c0000000770a9a00770a9a00000a9a0009000000a900000000eeee0000eeee0000eeee00a0000000cc0c0c0000000000
00066600000666000006660000665000c0000000a779af00a779af007709af00aa999999000000000eeeeee50eeeeee50eeeeee5000000000d00000000000000
06065a0606065a0606065a0600656500c00000000a7afe050a7afe05a77afe050900000000000000eeee2cc0eeee2cc0eeee2cc000000000cccc0c0c00000000
06665566066655660666556606505000c000000000a6665000a666500a76665000000000000000005e2255555e2255555e22555500000000d00d000000000000
05666665056666650566666565000000c0000000000775700007757000a77570000000000000000000ee2200aee0220090ee200000000000ccccc0c000000000
005f560f005f560f005f560f50000000c00000000006560000065600000656000000000000000000000ee22000ee0220000ee200000000000000000000000000
00056500000565000005650000000000c0000000000506000005060000050600000000000000000000ee22000ee0220000ee2000000000000000000000000000
00050500005005000005500000000000c0000000000606000060600000606000000000000000000000e020000e00200000e20000000000000000000000000000
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
fffffffff4ffffff04f4ff4000000000000000000000000004ffff4004ffff400ff4f44000000000000000000000000000000000000000000000000000000000
fffffffffffffff404ff4f4044444400444444440044444444444440044444440f00004000000000000000000000000000000000000000000000000000000000
ffffffffffffffff04fff440f44ff4404fff4fff044ff44f444ff440044fff4f0fff444000000000000000000000000000000000000000000000000000000000
ffffffffffff4fff044fff40f4f4ff40fff4fff404f4ff4ff4f4ff4004f4ff4f0f00004000000000000000000000000000000000000000000000000000000000
ffffffffffffffff04f4ff40f4ff4f40ff4fff4f04ff4f4ff4ff4f4004ff4f4f0ffff44000000000000000000000000000000000000000000000000000000000
ffffffff4fffffff04ff4f40f4fff440f4fff4ff04fff44ff4fff44004fff44f0f00004000000000000000000000000000000000000000000000000000000000
fffffffffff4ff4f04fff44044444440444444440444444444444400004444440ff4f44000000000000000000000000000000000000000000000000000000000
ffffffffffffffff044fff40044fff4000000000044fff4000000000000000000f00004000000000000000000000000000000000000000000000000000000000
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
000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a0a000cccccccc8888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080008080000000000000000000000080808080808080804000000000000000000000000000000000000000000000000000000000000000000000000000000000102000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232323232323232323232323232323232323232323232323232323232323232327f7f7f7f7f7f7f7f7f7f7f3232323232323232323232323232323232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232323232323232323232323232323232327f323232323232323232323232323232323232323232323232323232323232323232323232323232323232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232323232323232323232323232323232327f32323232323232323232323232323232323232323232323232327f7f7f7f7f7f7f323232323232323232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232323232323232323232323232323232327f7f3232323232323232323232323232323232323232323232323232327f7f7f7f7f7f7f3232323232323232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232323232327f7f7f7f7f7f32323232327f3232323232323232323232323232323232323232323232323232323232323232327f7f7f7f7f7f7f7f3232324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4232323232327f7f7f7f7f7f7f32327f7f327f323232323232323232323232323232323232323232323232323232323232323232327f7f7f323232327f7f324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42323232327f7f32323232327f327f7f7f327f32323232323232323232327f7f7f7f7f7f7f7f7f3232323232323232323232323232323232323232327f7f7f4200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232327f7f327f7f327f7f7f7f7f7f7f327f32323232323232323232327f7f7f7f32323232327f32323232323232323232323232323232323232327f327f4200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42323232323232323232323232327f3232327f3232323232323232323232323232327f323232327f323232323232323232323232323232323232327f7f32324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42323232323232323232323232327f3232327f7f32323232327f32320000327f327f7f3232327f7f007f7f32323232327f7f7f323232323232327f7f7f32324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423232323232323232323232323232327f7f7f7f7f7f007f3200000032003200323232327f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f327f327f7f7f7f7f32324200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
427f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f007f7f7f007f00007f7f007f0000007f7f7f0000000000000000007f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f4200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
423f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f7f7f003f3f00000000000000003f00003f0000000000000000000000003f00000000000000007f7f7f7f7f7f7f004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000000000000000000000000000007f000000000000000000000000003f3f003f0000000000003f3f003f3f003f3f000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000000000000000000000000000007f0000000000454444444444430000454444444444433f0000000000003f3f3f000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000000000000000000000000000007f0000000000420000000000000000000000000000420000000000003f3f3f3f000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000000000000000000000000000007f00000000004200000000000000000000000000004200000000003f3f3f3f3f000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4244444444444300000000000000000000007f00000000004200000000000000000000000000004200003f00003f3f3f3f3f000000000000004544444444444200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000004200000000000000000000007f0000000000420000000000000000000000000000420000000000003f3f3f3f000000000000004200000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000004200000000000000000000007f0000000000420000000000000000000000000000423f0000003f003f3f3f3f000000000000004200000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200000000007000000000000000000000007f0000000000000000000000000000000000000000000000000000003f3f3f3f000000000000007000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4200717171717000000000000000000000007f000000000000000000000000000000000000000000000000003f3f3f3f3f3f3f0000000000007072727272004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4548444444444444430000000000000000007f00000000000000000000004544444300000000000000003f3f3f3f3f3f3f3f000000000045444444444444484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248000000000000420000000000000000007f0000000000454444444444464141474444444444433f3f000000003f3f3f00000000000042000000000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
424800000000000042000000000000000000000000000045464141414141414141414141414141474300000000003f003f00000000000042000000000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248000000000000700000004544444443000000000045464141414141414141414141414141414147430000000000454444444300000070000000000000484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4248717171717171700000454141414141430000004546414141414141414141414141414141414141474300000045414141414143000070727272727272484200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

