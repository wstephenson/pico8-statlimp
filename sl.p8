pico-8 cartridge // http://www.pico-8.com
version 10
__lua__
-- vim: set ft=lua ts=1 sw=1 noet:
--current game state
state=nil
--table of all game states
states={}
--default states
states.splash={}
states.briefing={}
states.play={}
states.summary={}
states.gameover={}
-- all activities
activity={}
activity.mining={}
activity.collection={}
activity.rescue={}
activity.piracy={}
activity.fuelratting={}
-- legacy
activities={}
--hack
--global event timer
objtimer=0
--limpet list
limpets={}
current_limpet=0
names={"huey","dewey","louie","david","mike","sandy","adam","eddie","steve","ed","bo","zac","dale","groucho","chico","zeppo","harpo","alvin","simon","theodore","curly","larry","moe","barry","robin","maurice","andrea","caroline","sharon","jim","francis","joey","david","kim"}
limpet_colors={{8,3},{9,4},{10,4},{12,1},{14,2},{11,3},{13,5},{7,5}}
--mission status
mission={}
mission_number=0

function states.splash:init()
	dead_this_game={}
	self.next_state="briefing"
	self:init_activities_missions()
	current_limpet=1
end

function states.splash:draw()
	cls()
	local pc=9
	draw_ui_frame()
	camera(-8,-8)
	print("limpet control",28,0,pc)
	--print("--------------",0,6,pc)
	print("collect cargo",4,12,pc)
	print("rescue spacemen",4,18,pc)
	print("refuel stranded",4,24,pc)
	print("pirate traders",4,30,pc)

	print("drop when bay is blue",4,42,pc)
	print("avoid laser",4,48,pc)

	print("‹‘”ƒ to control thrust",4,60,pc)
	print("Ž (z key) to grab",4,66,pc)

	print("get correct item to refuel",4,78,pc)
	print("complete mission to restock",4,84,pc)
	print("(c)	3303 sYNpLEASURE ents.",4,104,pc)
	camera()
end

function states.splash:update()
	if(btnp(4) or btnp(5)) then update_state() end
end

function states.splash:init_activities_missions()
	mission_number=0 -- starts with 0
	activity.mining={
			name="mining",
			verb="mine",
			description={"grab required minerals ","","drop in scoop","","avoid mining laser"},
			material=0,
			scooprect={57,101,71,111}, -- aabb rect coords
			objects={16,17,18,19,20,21},
			missions={{{16,1,1}},{{18,2,1},{20,2,1}},{{21,3,1},{18,2,1},{19,1,1}}},
			init=function(state)
			end,
			draw_bg=function(state)
				-- asteroid
				circfill(64,-64,80,5)
				for i in all(state.burn_decals) do
					palt(0,false)
					palt(5,true)
					spr(24,i.x,i.y)
					palt()
				end

				camera(state.foffx,state.foffy)
				-- mining laser
				if(state:laser_on()) then
					local lcolor = 2
					if(flr(objtimer)%2==0)then
						lcolor = 14
					end
					line(state.lorigx,state.lorigy,state.laserx,state.lasery,lcolor)
				end
				camera()
			end,
			draw_hud=function(state)
				-- laser indicator
				-- TODO rethink
				--if (state.laser>0)then
				--	line(state.lorigx,126,state.lorigx,117+(state.laser/(state.laserson*30))*10,12)
				--else
				--	line(state.lorigx,126,state.lorigx,117-(state.laser/(state.lasersoff*30))*10,2)
				--end
			end,
			spawn_objects=function(state)
				if(state:laser_on())then
					if(objtimer % (20+flr(rnd(5)-2.5)) == 0)then
						obj = spawn_object(state,state.laserx,state.lasery,rnd(1)-0.5,rnd(1)+0.2,mission.objects[flr(rnd(#mission.objects))+1],30*8,0,true)
						add(state.burn_decals,{x=state.laserx-4,y=state.lasery-4,ttl=15})
						state:make_explosion(obj,obj.vx,obj.vy)
						sfx(7)
					end
				end
			end,
			envt_update=function(state)
				update_laser(state)
			end,
			envt_damage=function(state)
				do_laser_check(state)
			end,
			check_fail=function(state)
			end
			}
	activity.collection={
			name="collection",
			verb="collect",
			description={"collect asteroids","","required shown at top left","","drop them in scoop"},
			material=1,
			scooprect={57,101,71,111},
			objects={26,27,28,29,30,31},
			missions={{{26,1,2}},{{27,2,3},{28,2,3}},{{29,3,3}}},
			init=function(state)
				--init_static_objects(state)
			end,
			draw_bg=function(state)
			end,
			draw_hud=function(state)
			end,
			spawn_objects=function(state)
			end,
			envt_update=function(state)
			end,
			envt_damage=function(state)
			end,
			check_fail=function(state)
			end
	}
	activity.rescue={
			name="rescue",
			verb="rescue",
			description={"rescue lost humans","","drop them in scoop"},
			material=2,
			scooprect={57,101,71,111},
			objects={36},
			missions={{{36,1,3}},{{36,2,3}},{{36,3,3}}},
			init=function(state)
				init_static_objects(state,true)
			end,
			draw_bg=function(state)
				-- type-6 hull
				map(8,0,32,0,8,2)
				palt(0,false)
				palt(5,true)
				spr(24,48,0)
				spr(24,76,-2,1,1,true)
				palt()
			end,
			draw_hud=function(state)
			end,
			spawn_objects=function(state)
			end,
			envt_update=function(state)
				--wreck sparks
				local interval=((5+flr(rnd(3)-1.5))*3)
				if(objtimer%interval==0)then
					state:make_explosion({x=rnd(64)+32,y=rnd(16),material=0},0,0)
				end
			end,
			envt_damage=function(state)
				do_laser_check(state)
			end,
			check_fail=function(state)
				-- TODO fixme
				--return not state:critical_objects_present()
				return false
			end
	}
	activity.fuelratting={
			name="fuelratting",
			verb="refuel",
			description={"collect fuel bubbles","","refuel stranded trader"},
			material=0,
			scooprect={46,17,58,25},
			objects={35},
			missions={{{35,1,1}},{{35,2,1}},{{35,3,1}}},
			init=function(state)
			end,
			draw_bg=function(state)
				draw_hauler()
			end,
			draw_hud=function(state)
				rect(24,16-state.oxygen/20*16,25,16,12)
				if(state.oxygen<9)then
					map(0,3,21,0,2,1)
				end
			end,
			spawn_objects=function(state)
				if(objtimer % (45+flr(rnd(15)-7.5)) == 0)then
					spawn_object(state,0,32+rnd(64),rnd(2)+1,rnd(1)-0.5,42,-1,0,true)
				end
				state:do_fuel_bubble()
			end,
			envt_update=function(state)
				if(objtimer%30==0 and state.oxygen>0)then
					state.oxygen-=1
				end
			end,
			envt_damage=function(state)
			end,
			check_fail=function(state)
				return state.oxygen<=0
			end
	}
	activity.piracy={
			name="piracy",
			verb="pirate",
			description={"wait for shield drop","","collect dropped cargo","","avoid point defence"},
			material=1,
			scooprect={57,101,71,111},
			objects={43},
			missions={{{43,1,1}},{{43,2,1}},{{43,3,1}}},
			init=function(state)
			end,
			draw_bg=function(state)
				camera(state.foffx,state.foffy)
				local lcolor=9
				if(state:laser_on()) then
					if(objtimer%20<10)then
						line(state.lorigx,state.lorigy,state.laserx,state.lasery,lcolor)
					end
					-- target shield
					local shield_color=(objtimer%2==0 and 12 or 1)
					if(state.tshldf)then
						shield_color=12
						state.tshldf=false
					end
					circ(state.tshldx,state.tshldy,state.tshldr,shield_color)
				end

				draw_type6()

				if(objtimer%2==0)then -- thrust of both ships
					map(0,2,92,-4,2,1)
					map(0,2,96,120,2,1)
				end
				camera()
			end,
			draw_hud=function(state)
			end,
			spawn_objects=function(state)
				if(state:laser_on())then
					if(objtimer % 30 == 0)then
						obj = spawn_object(state,64,10,rnd(1)-0.5,rnd(1)+0.2,mission.objects[flr(rnd(#mission.objects))+1],30*8,0,true)
					end
				end
				if(state.limpet.health>0)then
					if(objtimer%3==0)then
						-- fire pdt
						state.pdt = objtimer % ((state.laserson/2+state.lasersoff*2)*30) - state.lasersoff*2*30
						if(state.pdt>0 and distance(state.x,state.y,80,6)<40)then
							sol=intercept({x=80,y=6},state,2)
							if(sol)then
								vx,vy=aimpoint_to_v_comps({x=80,y=6},sol,2)
								--bang
								spawn_object(state,80,6,vx,vy,41,60,1,true)
								sfx(14)
							end
						end
					 -- target shield effects
						if(state:hit_shield(state.tshldx,state.tshldy,state.tshldr,state)) then
							state.tshldf=true
							state:make_explosion(state,0,0)
							state.limpet.health-=state:laser_damage()
							if(state.limpet.health<0)then
								state:do_death()
							end
						end
					end
				end
			end,
			envt_update=function(state)
				update_laser(state)
				-- scroll bg stars when in motion
				for star in all(state.stars) do
					star.x+=0.4
					if(star.x>127)then star.x-=127 end
				end
			end,
			envt_damage=function(state)
				do_laser_check(state)
			end,
			check_fail=function(state)
			end
	}
	add(activities,activity.collection)
	add(activities,activity.mining)
	add(activities,activity.rescue)
	add(activities,activity.fuelratting)
	add(activities,activity.piracy)
end

function states.briefing:init()
	self.next_state="play"
	self.page=1
	populate_limpets()
	self:init_mission()
end

function states.briefing:draw()
	cls()
	print("briefing",48,8,9)
	draw_ui_frame(9)
	camera(-8,-8)
	if(self.page==1)then
		local h=draw_limpets_status(12,false,current_limpet)
		draw_mission_status(h+6)
	else
		printc(18,mission.name)
		local h=52-#mission.description*6/2
		for line in all(mission.description) do
			h+=printc(h,line)
		end
	end
	camera()
	if(self.page==2)then draw_drop_indicator(self) end
end

function states.briefing:update()
	objtimer+=1
	if(btnp(3))then
		current_limpet=next_live_limpet_index()
	end
	if(btnp(4) or btnp(5))then
		if(self.page==1)then
			self.page+=1
		else
			update_state()
		end
	end
end

function states.briefing:in_scoop()
	return false;
end

function states.briefing:init_mission()
	-- assumes game is made up of n activities x m missions
	-- this will break if activities do not each have the same number of missions
	local missioncount = #activities[1].missions
	local mission_i=flr(mission_number / missioncount)+1
	local activity_i=(mission_number % #activities)+1
	local activity=activities[activity_i]
	printh("mission_number "..mission_number..", #activities "..#activities..", activity_i "..activity_i..", name "..activity.name..", mission_i "..mission_i)
	local mission_data=activity.missions[mission_i]
	mission={}
	mission.name=activity.name
	mission.objects=activity.objects
	mission.verb=activity.verb
	mission.description=activity.description
	mission.material=activity.material
	mission.scooprect=activity.scooprect
	mission.required={}
	mission.complete=false
	--printh("mission: "..mission.name..", verb: "..mission.verb)
	for m in all(mission_data) do
		add(mission.required,{obj=m[1],goal=m[2],total=m[3],got=0})
		--printh("  obj: "..m[1]..", goal: "..m[2]..", total: "..m[3])
	end
end

function states.play:init_map()
	for i=1,16 do
		self.tiles[i]={}
		for j=1,48 do
			local s=0
			if((j-1)%4==0)then
				s=127+flr((j-1)/4)
			else
				s=flr(rnd(8)+48)
			end
			self.tiles[i][j]=s
		end
	end
end

function states.play:init()
	self.tiles={}
	-- the angle of the centre of the viewport, relative to world 0
	self.v_ang=0
	-- the angle of the origin of the world
	self.w_ang=0
	-- the angle of the limpet
	self.a=0
	-- the x coord of the limpet
	self.x=60
	-- other limpet flight stuff
	self.vx=0
	self.av=0
	self.tx=0
	self.ty=0
	--
	self:init_map()
	sfx(6)
	tinc=0.05
	tdec=tinc*2
	tmax=1
	maxv=3
	maxav=1
	self.tobj={}
	self.tobj.x=64
	self.tobj.a=0
	self.tobj.s=43
	self.pav=0
	self.lindex=current_limpet
	self.limpet=limpets[self.lindex]
	self.next_state="briefing"
	self.foffx=0
	self.foffy=0
	self.shldx=64
	self.shldy=160
	self.shldr=64
	self.tshldx=64
	self.tshldy=-32
	self.tshldr=50
	self.lorigx = 40
	self.lorigy = 113
	self.laser=0
	self.laserx=0
	self.lasery=0
	self.laserson=7
	self.lasersoff=8
	self.material=mission.material
	self.fuel_bubble=nil
	self.last_fuel_bubble=0
	self.oxygen=20
	self.txneg=false
	self.txpos=false
	self.tyneg=false
	self.typos=false
	self.grabber_cooldown=0
	self.grabbed=false
	self.object=nil
	self.stars={}
	self.particles={}
	self.burn_decals={}
	self.deathtimer=0

	self.objects={}
	self.dead_this_mission={}

	activity[mission.name].init(self)

	spawn_object(self,self.tobj.x,self.tobj.a,0,0,self.tobj.s,-1,0)
end

function states.play:draw_world()
	for track=1,16 do
		local sc=#self.tiles[track]
		for tile=1,sc do
			local s=self.tiles[track][tile]
			local th=tile/sc+(self.w_ang/100)+(self.v_ang/100)
			local cos_th=cos(th)
			if(cos_th>0)then
				local x=(track-1)*8+12+cos_th*12
				local y=sin(th)*60+64
				local c=5
				if(tile==1)then
					c=8
				else
					if(cos_th>0.85)then
						c=6
					else
						if(cos_th>0.5)then
							c=13
						end
					end
				end
				pal(6,c)
				spr(s,x,y)
				pal()
			end
		end
	end
end

function states.play:draw_object(obj)
	if(self.couldgrab)then
		pal(6,11)
		pal(12,10)
	end
	local th=(self.w_ang/100)+(obj.a/100)+(self.v_ang/100)
	local x=obj.x+12+cos(th)*6
	local y=sin(th)*56+64
	if(cos(th)>0)then
		spr(obj.s,x,y)
	end
	pal()
	return x,y
end

function states.play:draw()
	cls()
	self:draw_world()

	self:draw_debug()
	-- frame offset for motion effect

	-- background

	-- hud
--[[
	local spare=0
	for i=1,#limpets do
		local limpet=limpets[i]
		local x
		-- don't draw active limpet here
		if(limpet==self.limpet)then goto continue end
		spare+=1
		--if(spare==1) then
		-- x=24
		--else
		--	x=100
		--end
		local spritenum = (limpet.health>0 and i-1 or 25)
		pal(13,limpet.fg)
		pal(5,limpet.bg)
		spr(spritenum,9*(spare-1),18)
		pal()
  ::continue::
	end
--]]
	-- foreground objects

	-- drone
	pal(13,self.limpet.fg)
	pal(5,self.limpet.bg)
	local x,y=self:draw_object(self)
	-- drop shadow distance depends upon the magnitude of pav from -pav, whichis limited to +maxav
 --local sdist=12-8*(self.pav+maxav)/(2*maxav)
 local sdist=8
	palt(5,true)
	palt(0,false)
 spr(44,x+sdist,y+sdist)
	palt()

	-- TODO set the drone sprite when player chooses active drone
	--spr(self.lindex-1, self.x, y)
	spr(22,x-8,y)
	spr(23,x+8,y)
	pal()
	--]]
	-- grabbed object
	if(self.object != nil)then
		self:draw_object(self.object)
	end

	-- grabber
	if(self.grabbed)then
		spr(15, x, y-8)
	else
		spr(14, x, y-8)
	end	
	-- thrust
	local toff=0
	local tmin=0.001
	local tbig=tmax*0.66
	if(self.txneg)then
		sfx(2)
		if(abs(self.tx)>tbig) then
			toff=5
		end
		if(objtimer%2==0)then
			spr(4+toff,x+8, y)
		end
	end
	if(self.txpos)then
		sfx(2)
		if(abs(self.tx)>tbig) then
			toff=5
		end
		if(objtimer%2==0)then
			spr(5+toff,x-8, y)
		end
	end
	if(self.tyneg)then
		sfx(2)
		if(abs(self.ty)>tbig) then
			toff=5
		end
		if(objtimer%2==0)then
			spr(8+toff,x, y+8)
		end
	end
	if(self.typos)then
		sfx(2)
		if(abs(self.ty)>tbig) then
			toff=5
		end
		if(objtimer%2==0)then
			spr(6+toff,x-8, y)
			spr(7+toff,x+8, y)
		end
	end

	-- other objects
	for item in all(self.objects)do
		if(item != self.object) then
			local soffset=0
			-- special cased animation for spacemen
			if(item.s==36)then
				soffset = flr((objtimer%20) / 5)
			end
			self:draw_object(item)
		end
	end

 -- particles
	for p in all(self.particles) do
		local pcolor=0
		-- flames
		if(p.kind==0)then
			pcolor = p.ttl > 12 and 10 or (p.ttl > 7 and 9 or 8)
		end
		-- scrap
		if(p.kind==1)then
			pcolor = p.ttl > 12 and 7 or (p.ttl > 7 and 6 or 7)
		end
		-- gore
		if(p.kind==2)then
			pcolor = p.ttl > 12 and 8 or (p.ttl > 7 and 2 or 1)
		end
		-- fuel
		if(p.kind==3)then
			pcolor = p.ttl > 12 and ((rnd(1)>0.5) and 11 or 10) or (p.ttl > 7 and 3 or 5)
		end
		line(p.x,p.y,p.x-p.xv,p.y-p.yv,pcolor)
	end

	-- hud
 -- health
	local hpercent=self.limpet.health/100
	rect(126,126,127,127-hpercent*127,hpercent > 0.8 and 3 or (hpercent>0.5 and 11 or (hpercent>0.2 and 9 or 8)))

	--activity[mission.name].draw_hud(self)

	-- required items
	--self:draw_shopping_list()

	print(self.limpet.name,0,12,self.limpet.fg)
end

function states.play:draw_debug()
	if(true) then
		camera(0,-16)
		print("x:"..self.x, 0, 94, 7)
		print("ad:"..angular_distance(self,self.objects[1]), 0, 100, 7)
		print("cg:"..(self.couldgrab and "T" or "F"), 0, 107, 7)
		print("wa:"..self.w_ang, 42, 94, 7)
		print("av:"..self.av, 42, 100, 7)
		print("ty:"..self.ty, 42, 107, 7)
		print("la:"..self.a, 87, 94, 7)
		print("va:"..self.v_ang, 87, 100, 7)
		print("oa:"..self.objects[1].a, 87, 107, 7)
		--print("i:"..(self.object and self.object.c or '%'), 0, 114, 7)
		camera()
	end
end

function states.play:draw_shopping_list()
	local count=1
	for reqt in all(mission.required) do
		if(reqt.got < reqt.goal) then
			spr(reqt.obj,2+(count-1)*7,1)
			count+=1
		end
	end
	rect(0,0,2+(count-1)*8,10,9)
end

function states.play:update()
	-- update event timer
	objtimer+=1
	
 -- save previous acceleration for camera lag
	self.pav=self.av

	local vx = self.vx
	local av = self.av
	local x = self.x
	local a = self.a
	local grabbed = self.grabbed

	-- controls
	self.txpos=false
	self.txneg=false
	self.typos=false
	self.tyneg=false

	if(self.limpet.health>0)then

		if(btn(4) or btn(5))then
			if(not grabbed and self.grabber_cooldown==0) then
				sfx(0)
				grabbed = true
				self.grabber_cooldown=30
			end
		else
			grabbed = false
		end
		if(self.grabber_cooldown>0) then
			self.grabber_cooldown-=1
		end

		if(btn(0)) then
			self.txneg=true
		end
		if(btn(1)) then
			self.txpos=true
		end
		if(btn(2)) then
			self.tyneg=true
		end
		if(btn(3)) then
			self.typos=true
		end
	else -- dead
		self.deathtimer-=1
		if(self.deathtimer==2*30 or self.deathtimer==30)then
			self:make_explosion(self,0,0)
		end
		if(self.deathtimer==15)then
		 -- explosion sfx
		end
		if(self.deathtimer==0)then
			self.next_state="summary"
			update_state()
		end
	end

	-- set thrust from thruster flags
	-- x thrust
	if(self.txneg)then
		self:consume_fuel()
		self.tx=max(self.tx-tinc, -tmax)
	else
		if(self.txpos)then
			self:consume_fuel()
			self.tx=min(self.tx+tinc, tmax)
		else
			if(abs(self.tx)<0.01)then
				self.tx=0
			else
				self.tx-=self.tx/4
			end
		end
	end
	-- y thrust
	if(self.tyneg)then
		self:consume_fuel()
		self.ty=max(self.ty-tinc, -tmax)
	else
		if(self.typos)then
			self:consume_fuel()
			self.ty=min(self.ty+tinc, tmax)
		else
			if(abs(self.ty)<0.01)then
				self.ty=0
			else
				self.ty-=self.ty/4
			end
		end
	end
	-- apply acceleration
	vx+=self.tx
	av+=self.ty
	-- abs limits
	vx=clamp(vx,-maxv,maxv)
	av=clamp(av,-maxav,maxav)
	-- drag
	vx-=vx/12
	av-=av/12
	-- null out residuals
	if (abs(vx) < 0.005) then
		vx = 0
	end
	if (abs(av) < 0.005) then
		av = 0
	end
	-- update position
	x+=vx
	a+=av
	if(x<=0 or x>=120)then vx=0 self.tx=0 end
	if(a<=0)then a=99.999 end
 if(a>=100)then a=0 end

	x=clamp(x,0,120)

	-- save temporaries
	self.vx = vx
	self.av = av
	self.x = x
	self.a = a
	self.grabbed = grabbed

-- imported
	self.w_ang-=0.33
	self.w_ang=self.w_ang%100
 -- view tracks object, by negating obj's angle, and world angle
	self.v_ang=-(self.a+self.w_ang+self.pav)
	self.v_ang=self.v_ang%100	
-- import END
 --[[
	activity[mission.name].spawn_objects(self)

	activity[mission.name].envt_update(self)

	activity[mission.name].envt_damage(self)
	--]]

 -- move held object
	if(self.object)then
		self.object.x=self.x
		self.object.a=self.a+2
	end

	-- move objects
	for item in all(self.objects) do
		if(item!=self.object)then
			item.x += item.vx
			item.a += item.av
			item.a=item.a%100
			if(item.s!=42)then
				item.vx-=item.vx/(rnd(25)+75)
				item.av-=item.av/(rnd(25)+75)
			end
			if(item.ttl!=-1)then
				item.ttl-=1
			end
		end
	end
	-- object release
	if(not self.grabbed and self.object)then
		sfx(1)
		-- in scoop?
		if (self:in_scoop())then
			self:do_score(self.object)
			if(self:is_mission_complete())then
				sfx(5)
				mission_number+=1
				self.next_state="summary"
				update_state()
			end
			if(self.object==self.fuel_bubble)then self:remove_fuel_bubble()end
			del(self.objects,self.object)
			self.object=nil
		else
			self.object.x=self.x
			self.object.a=self.a+3
			self.object.vx=self.vx
			self.object.av=self.av+0.3
			self.object=nil
		end
	end

	-- collision detection
	for item in all(self.objects) do
		-- is it within the grab area
		-- the grab area is 8 pixels above the drone +- 4

		if(self.object==nil)then
			self.couldgrab=self:check_grabbable(self,item)
			if(self.grabbed==true and self.couldgrab)then
				self.object=item
			end
		end
	--[[
		local dead=false
		-- crashes
		if(item.collision and item!=self.object)then
			if(item.x > x-6 and item.x < x+6 and item.y > y-6 and item.y < y+6)then
				self.limpet.health-=collision_damage(item,self)
				if(self.limpet.health<0)then
					self:do_death()
				end
				dead=true
			end
		end
	--]]
		-- out of bounds, prune silently
		if(item.x<-8 or item.x>128)then
			if(item==self.fuel_bubble)then self:remove_fuel_bubble() end
			del(self.objects,item)
		end
	--[[
		-- hit shield
		if(item.s!=35 and self:hit_shield(self.shldx,self.shldy,self.shldr,item) and item!=self.object)then
			self.shldf=true
			dead=true
		end
	--]]
		-- too old
		if(item.ttl==0)then
			dead=true
		end
		if(dead)then
			if(item==self.fuel_bubble)then self:remove_fuel_bubble() end
			sfx(9)
			self:make_explosion(item,item.vx,-item.vy)
			del(self.objects,item)
		end
	end

	if(activity[mission.name].check_fail(self))then
		self.limpet.health=0
		self:do_death()
	end

	for p in all(self.particles) do
		p.x += p.xv
		p.y += p.yv
		p.xv *= 0.95
		p.yv *= 0.95
	end
	age_transients(self.burn_decals)
	age_transients(self.particles)
end

function states.play:check_collision(o1,o2)
	return abs(o1.x-o2.x)<5 and abs(o1.a-o2.a)<1
end
	
function states.play:check_grabbable(o1,o2)
	local ad = angular_distance(o1,o2)
	return abs(o1.x-o2.x)<5 and ad>2 and ad<3
end

function states.play:critical_objects_present()
	-- this needs to be updated on scoop
	local criticals_outstanding={}
	for i in all(mission.required) do
		for j=1,i.goal do
			add(criticals_outstanding,i.obj)
		end
	end

	for i in all(criticals_outstanding)do
		for j in all(self.objects)do
			if(j.c==i) then
				del(criticals_outstanding,i)
				break;
			end
		end
	end
	return #criticals_outstanding == 0
end

function states.play:make_explosion(point,xv,yv)
	xv=xv or 0
	yv=yv or 0
	for i=1,8 do
		add(self.particles,{x=point.x,y=point.y,xv=xv+rnd(2)-1,yv=yv+rnd(2)-1,ttl=20,kind=point.material})
	end
end

function states.play:consume_fuel()
	--self.limpet.health-=0.33
	if(self.limpet.health<30)then
		sfx(3,3)
	end
	if(self.limpet.health<=0)then
		self:do_death()
	end
end

function states.play:do_death()
	if(self.deathtimer==0)then
		sfx(-1,3)
		sfx(-1,2)
		self.limpet.health=0
		self.deathtimer=3*30
		self:make_explosion(self,0,0)
		self.txneg=false
		self.txpos=false
		self.tyneg=false
		self.typos=false
		self.grabbed=false
		self.tx=0
		self.ty=0
	end
end

function states.play:do_score(item)
	for i in all(mission.required) do
		if(i.obj==item.s)then
			sfx(15)
			self.limpet.health=min(self.limpet.health+20,100)
			if(self.limpet.health>=30)then
				sfx(-1,3)
			end
			i.got+=1
			self:do_drone_score(item)
			break
		end
	end
end

function states.play:do_drone_score(item)
	local found=false
	for i in all(self.limpet.score) do
		if(i.obj==item.s)then
			i.count+=1
			found=true
			break;
		end
	end
	if(not found) then
		add(self.limpet.score,{obj=item.s,count=1})
	end
end

function states.play:do_fuel_bubble()
	-- after 3 seconds with no bubble, generate a bubble
	if(self.fuel_bubble==nil and objtimer-self.last_fuel_bubble>3*30)then
		self.fuel_bubble=spawn_object(self,32,106,rnd(1)-0.5,-(rnd(0.8)+0.2),35,-1,3,true)
	end
end

function states.play:hit_shield(sx,sy,sr,item)
	local i_off_x=item.x-sx
	local i_off_y=item.y-sy
	return((i_off_x*i_off_x + i_off_y*i_off_y) < (sr * sr))
end

function states.play:in_scoop()
	return false
	--return (self.object.x>=mission.scooprect[1] and self.object.x<=mission.scooprect[3] and self.object.y>=mission.scooprect[2] and self.object.y<=mission.scooprect[4])
end

function states.play:is_mission_complete(dropped_object)
	local complete = true
	for i in all(mission.required) do
		complete = complete and (i.goal<=i.got)
	end
	mission.complete=complete
	return complete
end

function states.play:laser_hit()
	p0={x=self.x+1,y=self.y}
	p1={x=self.x+6,y=self.y}
	p2={x=self.x+6,y=self.y+7}
	p3={x=self.x+1,y=self.y+7}
	drone_hit_box={p0,p1,p2,p3}
	return line_intersects_convex_poly(self.lorigx,self.lorigy,self.laserx,self.lasery,drone_hit_box)
end

function states.play:laser_damage()
	return 2
end

function states.play:laser_on()
	return self.laser > 0 and self.limpet.health > 0
end

function states.play:remove_fuel_bubble()
	self.last_fuel_bubble=objtimer
	self.fuel_bubble=nil
end

function spawn_object(state,x,ang,vx,av,s,ttl,material,collision)
	local obj={}
	obj.x=x
	obj.a=ang
	obj.vx=vx
	obj.av=av
	obj.s=s
	obj.ttl=ttl
	obj.material=material
 obj.collision=collision
	add(state.objects,obj)
	return obj
end

-- 3 way switch: play(next life), briefing(new mission), gameover
function states.summary:init()
	sfx(-1,2)
	sfx(-1,3)
	if(mission.complete)then
		self:reap_dead_limpets()
		self.next_state="briefing"
	else
		if(self:they_are_all_dead())then
			self:reap_dead_limpets()
			self.next_state="gameover"
		else
			if(limpets[current_limpet].health<=0)then
				current_limpet=next_live_limpet_index()
			end
			self.next_state="play"
		end
	end
end

function states.summary:draw()
	cls()
	draw_ui_frame()
	camera(-8,-8)
	print("status",44,0,9)
	local not_in_mission=(mission.complete or self:they_are_all_dead())
	local h=draw_limpets_status(12,true,(not_in_mission and 0 or current_limpet))
	h=draw_mission_status(h+6,not_in_mission)
	draw_rip_status(h,states.play.dead_this_mission)
	camera()
end

function states.summary:update()
	objtimer+=1
	if(btnp(3))then
		current_limpet=next_live_limpet_index()
	end
	if(btnp(4) or btnp(5)) then
		for i in all(states.play.dead_this_mission) do
			add(dead_this_game,i)
		end
		self.dead_this_mission={}
		update_state()
	end
end

function states.summary:reap_dead_limpets()
	for limpet in all(limpets)do
		if(limpet.health<=0)then
			add(states.play.dead_this_mission,limpet.name)
			del(limpets,limpet)
		end
	end
end

function states.summary:they_are_all_dead()
	return next_live_limpet_index()==0
end

function states.gameover:init()
	sfx(4)
	self.next_state="splash"
end

function states.gameover:draw()
	cls()
	local pc=9
	draw_ui_frame()
	camera(-8,-8)
	print("game over :(",32,0,9)
	draw_rip_status(12,dead_this_game)
	camera()
end

function states.gameover:update()
	if(btnp(4) or btnp(5)) then
		dead_this_game={}
		update_state()
	end
end

function update_state()
	local next_state=states[state].next_state
	if(next_state)then
		state=next_state
		states[state]:init()
	end
end

function angular_distance(o1,o2)
	local naive_d=o1.a-o2.a
	local shortest_d=0
	if(abs(naive_d)>50)then -- 50 is half the max angle of 100
		shortest_d=100-abs(naive_d)
		if(o1.a>o2.a)then
			shortest_d=-shortest_d
		end
	else
		shortest_d=naive_d
	end
	return shortest_d
end

function collision_damage(o1,o2)
	local dx=o1.vx-o2.vx
	local dy=o1.vy-o2.vy
	local vsquared=(dx*dx+dy*dy)
	return vsquared*5
end

function draw_ui_frame()
	local fr=function(c)
		rect(4,4,123,123,c)
		line(4,15,123,15,c)
	end
	camera(-1,-1)
	fr(4)
	camera()
	fr(9)
end

function age_transients(transient_array)
	for t in all(transient_array) do
		t.ttl-=1
			if t.ttl < 0 then
				del(transient_array,t)
			end
	end
end

function clamp(val,minv,maxv)
	return max(minv,min(val,maxv))
end

function aimpoint_to_v_comps(src,aim,pv)
	local dy = aim[2]-src.y
	local dx = aim[1]-src.x
	local a=atan2(dx,dy)
	local shotvx=pv*cos(a)
	local shotvy=pv*sin(a)
	return shotvx,shotvy
end

function intercept(src,dst,v)
	local tx=(dst.x-src.x)/4
	local ty=(dst.y-src.y)/4
	local tvx=dst.vx/4
	local tvy=dst.vy/4
	local v = v/4

	-- get quadratic components
	local a = tvx*tvx + tvy*tvy - v*v
	local b = 2*(tvx*tx+tvy*ty)
	local c = tx*tx + ty*ty
	assert( c>0)

	-- solve quadratic
 local ts = quad(a,b,c)

 -- find smallest positive solution
	local sol = nil
	if(ts != nil)then
		local t0=ts[1]
		local t1=ts[2]
		--printh("t0: "..t0..",t1: "..t1)
		local t=min(t0,t1)
		if(t<0)then
			t=max(t0,t1)
		end
		if(t>0)then
			sol={(dst.x+dst.vx*t),(dst.y+dst.vy*t)}
		end
	end
	return sol
end

function quad(a,b,c)
	local sol=nil
	if(abs(a)<0.00001)then
		if(abs(b)<0.00001)then
			if (abs(c)<0.00001) then
				--printh("a,b,c are zero")
				sol={0,0}
			end
		else
			sol={-c/b,-c/b}
		end
	else
		local disc = b*b-4*a*c
		if(disc>=0)then
			disc=mysqrt(disc)
			assert(disc!=32768)
			a=2*a
			sol={(-b-disc)/a,(-b+disc)/a}
		else
			--printh("disc is negative")
		end
	end
	return sol
end

function mysqrt(x)
	if x <= 0 then return 0 end
	local r = sqrt(x)
	if r < 0 then return 32768 end
	return r
end

function distance(x1,y1,x2,y2)
	local x=x1-x2
	local y=y1-y2
	return mysqrt(x*x+y*y)
end

function do_laser_check(state)
	if(state:laser_on())then
		-- has laser hit limpet?
		local hit
		local hx
		local hy
		hit,hx,hy=state:laser_hit()
		if(hit)then
			-- only do laser damage on every 3rd update
			if(objtimer % 3 == 0)then
				state:make_explosion({x=hx,y=hy},0,0)
				state.limpet.health-=state:laser_damage()
				if(state.limpet.health<0)then
					state:do_death()
				end
			end
		end
	end
end

function draw_type6()
	map(8,0,32,0,8,2)
end

function draw_hauler()
	map(2,2,32,0,6,2)
end

function draw_own_ship(state)
	camera(state.foffx,state.foffy)
	-- ship hull
	map(0,0,32,112,8,2)
	-- drop indicator
	if(state.object and ((objtimer%15)<7 or (objtimer%10==0 and state:in_scoop())))then
		draw_drop_indicator(state)
	end
	local shield_color=1
	if(state.shldf)then
		shield_color=12
		state.shldf=false
	end
	-- ship shield
	circ(state.shldx, state.shldy, state.shldr, shield_color)
	camera()
end

function draw_drop_indicator(state)
	local sr=mission.scooprect
	local icolor=9
	if(state==states.play)then
		if(state:in_scoop())then
			icolor=12
			sfx(11)
		else
			icolor=9
			sfx(10)
		end
	end
	line(sr[1],sr[2],sr[1]-1,sr[2]-1,icolor)
	line(sr[1],sr[4],sr[1]-1,sr[4]+1,icolor)
	line(sr[3],sr[2],sr[3]+1,sr[2]-1,icolor)
	line(sr[3],sr[4],sr[3]+1,sr[4]+1,icolor)
end

function draw_limpets_status(yorig,score,active)
	yorig=yorig or 0
	score=score or false
	active=active or 0
	local pc=9
	print("your limpets"..(active>0 and " (ƒ cycle)" or ""),0,yorig,pc)
	yorig+=6
	for i=1,#limpets do
		local limpet = limpets[i]
		if(active == i and objtimer % 30 < 15)then
			spr(34,0,yorig)
		end
		-- HACK
		if(limpet.health<0) then limpet.health=0 end
		print(""..i..". "..limpet.name.." : "..limpet.health.."%",4,yorig,limpet.health>0 and limpet.fg or 5)
		yorig+=6
		if(score and #limpet.score>0)then
			for i=1,#limpet.score do
				local score_item=limpet.score[i]
				print(score_item.count,8+11*i,yorig,(score_item.count>2 and (score_item.count>4 and 10 or 6) or 9))
				spr(score_item.obj, 12+11*i-1,yorig-1)
			end
			yorig+=6
		end
	end
	return yorig
end

function draw_mission_status(yorig, retro)
	yorig=yorig or 0
	retro=retro or false
	local pc=9
	print(((mission_number==0 or retro) and "" or "next, ")..mission.verb,0,yorig,pc)
	yorig+=6
	for j=1,#mission.required do
		local requirement=mission.required[j]
		local i=requirement
		spr(requirement.obj,4,yorig)
		print(' x ',12,yorig,12)
		print(requirement.goal.." ("..requirement.got..")",24,yorig,requirement.got>=requirement.goal and 11 or 8)
		yorig+=6
	end
	if(mission.complete)then
		yorig+=6
		print("well done!!!",0,yorig,pc)
		yorig+=6
	end
	return yorig
end

function draw_rip_status(yorig,dead_list)
	yorig=yorig or 0
	if(#dead_list>0)then
		yorig+=6
		print("rip ",0,yorig,9)
		for i=1,#dead_list do
			print(dead_list[i],16+(i-1)*4*6,yorig,4)
		end
		yorig+=6
	end
	return yorig
end

function printc(yorig,string,color)
	color=color or 9
	local x=64-8-(#string*4)/2
	print(string,x,yorig,color)
	return 6
end

function init_static_objects(state,collision)
	-- create array of object types containing required ones
	local objs={}
	for i in all(mission.required) do
		for j=1,i.total do
			add(objs,i.obj)
		end
	end

	for i in all(objs) do
		spawn_object(states.play,rnd(100+10),rnd(80)+20,0,0,i,-1,mission.material,collision)
	end
end

function line_intersects_convex_poly(x1,y1,x2,y2,poly)
	-- returns bool,x,y (hit, one point of intersection if hit)
	local hit
	local hitx
	local hity
	local point1
	local point2
	for i=1,count(poly) do
		if i<count(poly) then
			point1 = poly[i]
			point2 = poly[i+1]
		else
			point1 = poly[i]
			point2 = poly[1]
		end
		hit,hitx,hity=line_intersects_line(x1,y1,x2,y2,point1.x,point1.y,point2.x,point2.y)
		if hit then return hit,hitx,hity end
	end
	return false,0,0
end

function line_intersects_line(x0,y0,x1,y1,x2,y2,x3,y3)
	local s
	local t
	local s1x = x1-x0
	local s1y = y1-y0
	local s2x = x3-x2
	local s2y = y3-y2
	local denom=-s2x*s1y+s1x*s2y
	s=(-s1y*(x0-x2)+s1x*(y0-y2))/denom
	t=(s2x*(y0-y2)-s2y*(x0-x2))/denom
	if(s>=0 and s<=1 and t>=0 and t<=1) then
		-- intersection!
		return true,x0+t*s1x,y0+t*s1y
	else
		return false,0,0
	end
end

function next_live_limpet_index()
	local i = current_limpet
	if(#limpets==0)then
		return 0
	end
	while(true)do
		i+=1
		-- back to start and none alive
		if(i==current_limpet)then
			i=0
			break
		end
		if(i>#limpets)then
			i=1
		end
		if(limpets[i].health>0)then
			break
		end
	end
	return i
end

function populate_limpets()
	-- renew the gang
	assert(#names>0)
	while(#limpets<3)do
		colorscheme=limpet_colors[1]
		add(limpets,{name=names[1],health=100,score={},fg=colorscheme[1],bg=colorscheme[2]})
		del(limpet_colors,colorscheme)
		add(limpet_colors,colorscheme)
		del(names,names[1])
	end
end

function update_laser(state)
	-- move laser aim
	state.laserx=64+sin((objtimer%100)/100)*20
	state.lasery=8+cos((objtimer%100)/100)*5

	-- update laser state
	state.laser = objtimer % ((state.laserson+state.lasersoff)*30) - state.lasersoff*30
	if(state.laser>0)then
		sfx(8,2)
	else
		sfx(-1,2)
	end

	-- laser burn trace
	if(state.laser>0 and objtimer % 2 == 0)then
		add(state.particles,{x=state.laserx,y=state.lasery,xv=0,yv=0,ttl=10})
	end
end

function _init()
	state="splash"
	states[state]:init()
end

function _draw()
	states[state]:draw()
end

function _update()
	states[state]:update()
end
__gfx__
0dddddd00dddddd00dddddd000000000000000000000000000000001100000000000000000000000000000000000000cc0000000000770000000000000000000
0d11dd500d111d500d111d500000000000000000000000000000000cc0000000000cc0000000000000000000000000077000000000c77c000000000000000000
0dd1dd500ddd1d500dd11d5000000000000000000000000000000000000000000001100000000000000000000000000000000000001cc1000000000000000000
ddd1dd5ddd1ddd5ddddd1d5d000000000c100000000001c000000000000000000000000007c1000000001c700000000000000000000cc0000300003000033000
0d111d500d111d500d111d500000000000000000000000000000000000000000000000000000000000000000000000000000000000011000b030030b00b33b00
0ddddd500ddddd500ddddd500000000000000000000000000000000000000000000000000000000000000000000000000000000000011000b000000b00b00b00
0ddddd500ddddd500ddddd5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000b00b0000b0
05555550055555500555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000b00b0000b0
00000000000000000000000000000000000000000000000000000000000000005555555500000000000000000000000000000000000000000000000000000000
000444000003300000000b000ccc0000002222000009900000000000000000005550505500022000000000000000000000000000000000000000000000000000
0040044000300300000bb0b00c0c000002000200099009900000000dd00000005050055500022000000777000007760000077600000677000007770000067700
004044400303330000b00bb00c0cc00002022220090999900000000dd00000005502200502222220007666600077766000666660006666600066667000667770
004444000333330000bbbbb00cccccc0022222200999900000000000000000005002805502222220007666600077766000666660006666600066667000667770
00044000003330000bbbbb00000cccc0002222000099000000000000000000005550050500022000000655000006650000066500000566000005560000056600
000000000000000000bb00000000cc00002220000099000000000000000000005505055500022000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005555555500022000000000000000000000000000000000000000000000000000
0000000000000000ccc0000000333300000000000000000000000c0000c00000000000c000000000000000000000000055050505000000000000000000000000
0000000000ccc000ccc000000ab000b0000c0c0000c0000000000c00000c0000000c0c0c00000000000000000000775050505055000000000000000000000000
000677000cc0cc00ccc000003b303333000cc0c00c0c0c0000c0c00ccc0c00000000ccc000000000000080800006677055050505000000000000000000000000
0066666000c0c0000c0000003b300353000ccc0000ccc000000cccc000ccccc000cccccc000b000008089898006c665050505055000000000000000000000000
0066666000ccc000c0c00000033035300cccc0000ccccc0000ccc000000ccc000c00c000000000008889977806c6c50055050505000000000000000000000000
000566000c0c0c000000000000333300c00c0c000000c0cc0c0cc00000c0c0c0000c00000000000008089898066c500050505055000000000000000000000000
000000000c0c0c00000000000000000000c000000000c00000c0c00000000c00000c000000000000000080800065000055050505000000000000000000000000
0000000000000000000000000000000000c0000000000c0000000000000000000000000000000000000000000000000050505055000000000000000000000000
66666666660066006060606066666666606060606006060606666660666666660000000000000000000000000000000000000000000000000000000000000000
66666666660066006060606000000000060606066006066660666606600000000000000000000000000000000000000000000000000000000000000000000000
66666666006600666060606066666666606060606006060666066066606666660000000000000000000000000000000000000000000000000000000000000000
66666666006600666060606000000000060606066006066666600666606000600000000000000000000000000000000000000000000000000000000000000000
66666666660066006060606066666666606060606006060666600666606666660000000000000000000000000000000000000000000000000000000000000000
66666666660066006060606000000000060606066006066666066066606000660000000000000000000000000000000000000000000000000000000000000000
66666666006600666060606066666666606060606006060660666606606000660000000000000000000000000000000000000000000000000000000000000000
66666666006600666060606000000000060606066006066606666660606666660000000000000000000000000000000000000000000000000000000000000000
00000000000000bbbbb0000000000000000000000000000000000000000000000000000000000077777000000000000000000000000000000000000000000000
00000000000bbb00000bbbbbbbbbbbbbbbbbbbbb0000000000000000b00000000000000000077700000777777777777777777777000000000000000070000000
00000000bbb00333bbb000000b00000000000000bbbb0000000000bb0bb000000000000077700000777000000700000000000000777700000000007777700000
0000bbbb00033bbb000333330b0333333330bbb00000bbbb0000bb00300bb0000000777700000777000000000700000000007770000077770000770000077000
0003b00033bbb000333333330b0333333333000333330000bbbb003333300bb00007700000777000000000000700000000000000000000007777000000000770
003eb333bb0003333333333330b0333333333333333333330000bbbb3330b0b0007c700077000000000000000070000000000000000000000000777700000070
03eeb3bb003333300333333330b03333333333333333333333330000bbbb30b007cc707700000000000000000070000000000000000000000000000077770070
03eebb003333330cc033333330b000000333333333333003333333330000bbb007cc770000000007700000000070000000000000000000000000000000007770
03333b000003333003333333330bbbbbb000000333330cc0333333333333330b0777770000000007700000000007777770000000000007700000000000000007
03eeeebbbbb0000003333333333000000bbbbbb000000003333333333333330b07cccc7777700000000000000000000007777770000000000000000000000007
003eeebe000bbbbb00000333333333333000000bbbbbb000003333333333000b007ccc7c00077777000000000000000000000007777770000000000000000007
000333eebb000000bbbbb000003333333333333000000bbbbb0000003330cc0b000777cc77000000777770000000000000000000000007777700000000007707
00000033bbb000bb00000bbbbb000000333333333333300000bbbbbb0000000b0000007777700000000007777700000000000000000000000077777700000007
000000000b0bbb000333300000bbbbbb000000333333333333000000bbbbbbbb0000000007077700000000000077777700000000000000000000000077777777
0000000000b000bbb000333333000000bbbbbb0000003333333333330000000b0000000000700077700000000000000077777700000000000000000000000007
00000000000bb0000bbb000333333333000000bbbbbb0000003333333333330b0000000000077000077700000000000000000077777700000000000000000007
00002cc20eeee020eeeee02000020eeeeeeeeeeeeeeeeeeeeeeeeee02e0200000077777777000000000000000000000000000000000444444440000000000000
00002cc20eeee020eeeee02222220eeeeeeeeeeeeeeeeeeeeeeeeee02e0200000711111111700000000000000000000000000000004000000040000000000000
00002cc200000020eeeeee000000eeeeeeeeeeeeeeeeeeeeeeeeeee02e020000711a11aa1a170000000000000000000000000000440999999904000000000000
0000222222222220eeeeee0000eeeeeeeeeeeee0000eeeeeeeeeeee02e02000071a1a11a1a117000000000000000000000000004099999999904000000000000
00002cc200000020eeeee088880eeeeeeeeeee088880eeeeeeeee0002e02000071a1a1a111111700000000000000000000000440000000999904000000000000
000002c20eeee020eeeee088880eeeeeeeeeee088880eeeeee000222e0200000711a11aa1a171700000000000444444444444444444444000044000000000000
000000222000e020eeeeee0000eeeeeeeeeeeee0000eeee00022200e020000000711111111707700000000444000000000000000000000444400000000000000
00000000022200200000000000000000000000000000000222000ee0200000000077777777000000000444000909999999999999999099400000000000000000
000c100000222222222222222222222222222222222222200eeee0220000000000000000000000044440009990c0999999999999990409440000000000000000
00cc1c1000002200000000000000000000022222222200222000020000000000000000000000004b400994449909999944444444404c40404000000000000000
0c7ccc1000000022eeeeeeeeeeeeeeeeee20000000000000022220000000000000000000000004bb409999449999999400000000490409404000000000000000
077777cc000000002222222222222222220000000000000000000000cc1110000000000000004044400000000000004099999999099090404000000000000000
077777cc000000000000000000000000000000000000000000000000cc1110000000000000040999444444444444440999999990999990404000000000000000
0c7ccc10000000000000000000000000000000000000000000000000000000000000000000040000009999000000000009999990000000404000000000000000
00cc1c10000000000000000000000000000000000000000000000000000000000000000000044444440000444444444440000004444444440000000000000000
000c1000000000000000000000000000000000000000000000000000000000000000000000000000004444000000000044444444000000000000000000000000
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
00000000111111112222222233333333444444445555555566666666777777778888888899999999aaaaaaaabbbbbbbbccccccccddddddddeeeeeeeeffffffff
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
__label__
99999999999000000000000000000000000000000000000000000000000000000004444444400000000000000000000000000000000000000000000000000000
90003333009000000000000000000000100000000000000000000000000000000040000000400000000000000000000000000000000000000000000000000000
900ab000b090000000000000cc000000000000000000000000000000000000004409999999040000000000000000000000000000000000000000000000000000
903b30333390000100000000cc0000000000000000000000000000000000000409999999990400000000000000000000000000000000000000000000000c0000
903b30035390000000000000cc000000000000000000000000000000000004400000009999040000000000000000000000000000000000000000000000000000
900330353090000000000000cc000000000000000000000004444444444444444444440000440000000000000010000000000000000000000000000000000000
900033330090000000000000cc000000000000000000004440000000000000000000004444010000000000000000000000000000000000000000000000000000
900001000090000000000000cc000000000000000004440009099999999999999990994000000000000000000000000000000000000000000000000000000000
900000000090000000000000cc000000000000044440009990c09999999999999904094400000000000000000000000000000000000000000000000000000000
900000000090000000000000cc0000000000004b400994449909999944444444404c404040000000000000000000000000000000000000000000000000000000
999999999990000000000000cc000000000004bb4099994499999994000000004904094040000000000000000000000000000000000000000000000000000000
000000000000100000000000cc00000000004044400000000000c040999999990990904040000000000000000000000000000000000000000000000000000000
909090909990909000000000cc000000000409994444444444444409999999909999904040000000000000000000000000000000000000000000000000000001
909090909000909000000000cc000000000400000099990000000000099999900000004040000000000000000000000000000000000000000010000000000000
999090909900999000000000cc000000000444444400004444444444400000044444444400000000000000000000000000000000000000000000000000000000
909090909000009000000000cc000010000000000044440000000000444444440000000000000000000000000000000000000000000000000000000000000000
909009909990999000000000cc00000000000000000000000000000000000000000000000010000000000000000000c000000001000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000033
00000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
0000000000000000000000000000000000c000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000033
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000033
000c00000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000033
00c00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000c00000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000100000000000c00000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000033
000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000008080000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008089898000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088899778000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008089898000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000033
000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000010000000000000001000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
0000000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000001000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
0c000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000c01000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010033
0000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000c033
0000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000033330000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000abc00b000000000000000000000000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000003b30333300000000000003000030000000000000100000000000000000000000000000000000000000000033
00000000000000000000000000000000000000003b300353000000000000b030030b000000000000000000000000000000000000000000000000000000000033
000000000000000000000000000000000000000003303530000000000000b000000b000000000000000000000000000000000000000000000000000000000033
0000000000000000000000000000000000000000003333000000000000000b0000b000000000000000000000000000000000cc00000000000000000000000033
0000000000000000000000000000000000000000000000000000000000000b0000b0000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000009999990000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000009009940000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000909909940900000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000999909949900000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000009000940000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000009999940000000000000000000000000000000000000000000000000000000000033
0000000000000000000000c000000000000000000000000000000000000009999940000000000000000000000000000000000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000004444440000000000000000000000000000000000000000000000000000000000033
00000000100000000000000000000000000100000000000000000000000000000000000000000000000000000000000100000000000000000000000000000033
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033
000000000000000000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000033
000000000000000000000000000000000000000000000000000c000000c000000000000000000000000000000000000000000c00000000000000001000000033
00000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000033
0000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000c000000000000000000033
00c000000000000000000000000000000000000000000c000000001c00000000000000000000c000000000000000000000000000000000000000000000000033
000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000033
000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0033
00000000000000000000000000000000000000000000000000000000011111111111111100000000000000000000000000000000000000000000000000000033
00000000000001000000000000000000000000000000000000011111100000000000000011111100000000000000000000000000000000000000000000000033
0000000000000000000000000000000000000000000000011110000000000000000000000000001111000000000000000000c000000000000000000000000033
00000000000000000000000000000000000000000000111000000000000000000000000000000000001110008080000000000000000000000000000000000033
00000000000000000000000000000000000000000111000000000000000000000000000000000000000008189898000000001000000000000000000000000c33
00000000000000000000000000000000000000011000000000000000000000000000000000000000000088899778000000000000000000000000000000000033
00000000000000000000000000000000000011100000000000000000000000000000000000000000000008089898100000000000000000000000000000000033
0000000000000000000000000000000000110000000000000000000000000c000000000000000000010000008080011000000000000000000000000000000033
00000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000033
00000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000033
00000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000110000000000000000000000000033
00000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000033
00000000000000000000000000010000000000000000000000000000000000000000000000000001000000000000000000000100001000000000000000000033
00000000000000c0000000000110000000000000010000000000000000000000000000000000000c000000000000000000000011000000000000000000000033
00000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000033
00000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000033
0000000000000000000000100000000000000000000000bbbbb00000000000000000000000000000000000000000000000000000001000000000000000000033
0000000000000000000001000000000000000000000bbb00000bbbbbbbbbbbbbbbbbbbbb0000000000000000b000000000000000000100000000000000000033
0000000000000000000110000000000000000000bbb00333bbb010000b00000000000000bbbb0000000000bb0bb0000000000000000011000000000000000033
000000000000000000100000000000000000bbbb00033bbb000333330b0333333330bbb00000bbbb0000bb00300bb00000000100000000100000000000000033
000000000000000000100000000000010003b00033bbb000333333330b0333333333000333330000bbbb003333300bb000000000000000100000000000000033
00000000000000000100000000000000003eb333bb0003333333333330b0333333333333333333330000bbbb3330b0b000000000000000010000000000000033
000000000000000010000000c000000003eeb3bb003333300333333330b03333333333333333333333330000bbbb30b000000000000000001000000000000033
1000000000000001000000000000000003eebb003333330cc033333330b000000333333333333003333333330000bbb000000000000000000100000000000033
0000000000000010000000aaaaaa000003333b000003333003333333330bbbbbb000000333330cc0333333333333330b00000cccccc000000010000000000033
0000000000000100000000a000a4000003eeeebbbbb0000003333333333000000bbbbbb000000003333333333333330b00000c000c1000000001000000000033
0c00000000000100000000aaa0a40000003eeebe000bbbbb00000333333333333000000bbbbbb000003333333333000b00000cc00c1000000001000000000033
000000000000100000000aa0aaa4a000000333eebb000000bbbbb000003333333333333000000bbbbb0000003330cc0b0000cccc0c1c00000000100000000033
0000000000010000000000a000a4000000000033bbb000bb00000bbbbb000000333333333333300000bbbbbb0000000b00000c000c1000000000010000000033
0000000000100000000000aaaaa40000000000c00b0bbb000333300000bbbbbb000000333333333333000000bbbbbbbb00000ccccc1000000000001000000033
0000000000100000000000aaaaa400000000000000b000bbb000333333000000bbbbbb0000003333333333330000000b00000ccccc1000000000001000000033
0000000001000000000000444444000000000000000bb0000bbb000333333333000000bbbbbb000000333333333333cb00000111111000000000000100000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4041424344454647606162636465666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50515253545556573f7172737475763f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7077786a6b6c6d6e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6869797a7b7c7d7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000c3200c3300a3300230022350233502435022340233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001e33021350213401d330213000b3300c3400c3400b3300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000039610396103a6003a60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000d0a5000a5000a5002b5002c500005003335035350333503535033350005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000e0000310503604024050280401b0501e0400605006050060200601000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0107000013050131500010013050131500010013050131501a1001805018150101001805018150181001805018150001001f0501f1501d1001f0501f150001001f0501f1501f1002405024150240502414024140
00130000182501a2401c25020240202401d2402024020240202001d2002020024200182001a2001c20022200182001a2001c20021200182001a2001c200202001e2001d200202000020000200002000020000200
000200002f6410565130651056512f6510565128651066512065111641106310d6310b6210a621096210962108621076210761105611056110561103611000010000100001000010000100001000010000100001
000300002154019130046100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000f6300d640126500d650126500d650126400d6300b62009610086100d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000003225030200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
001000003d25000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
00040000394703a4700140013400124003a4003a4001b400394503a4503a4003d4003d400004000040000400394503a4503a4003a40000400004000040000400394503a4503a4003a40000400004000040000400
000500003b140396402814027630000001413012620000000d6100b60008110066100760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002b4501e450194500040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
01060000000042a0542c054360543a0543b0543b0543b034000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004
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

