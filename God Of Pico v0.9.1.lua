-- thれちm hiニめ♥u ニめたng cニめ◆ lay mニむくnh khi rれてu bay ngang qua
kratos = {
 hp = 10,
 max_hp = 10,
 samira = 70,
 max_samira = 100,
 x = 40, y = 80,
 dx = 0, dy = 0,
 w = 8, h = 8,
 on_ground = false,
 facing = 1,
 anim_timer = 0,
 anim_frame = 0,
 state = "idle",
 wall_slide = false,
  _was_on_ground = false,
 knockback_timer = 0,
 carrying = nil,
 level = 1,
 exp = 0,
 exp_to_next = 3,
 wall_jump_lock = 0,
 inventory = {}
}

-- dong vat --
cows = {}

axe = {
 x = 0, y = 0,
 dx = 0, dy = 0,
 thrown = false,
 returning = false,
 grounded = false,
 recall_delay = 0,
 speed = 3,
 spin_timer = 0,
 spin_frame = 0,
 damage = 2,
 id = 0
}

camera_shake = 0
can_throw_axe = true
show_inventory = true
show_stats = false

wind_time = 0
wind_power = 0

-- axe charge
axe_charge = 0
axe_max_charge = 30
axe_charging = false
axe.want_to_recall = false


-- danh sach boses 
monsters = {}
particles = {}

function gain_exp(amount)
  kratos.exp += amount
  while kratos.exp >= kratos.exp_to_next do
    kratos.exp -= kratos.exp_to_next
    kratos.level += 1
    kratos.max_hp += 2
    kratos.hp = kratos.max_hp
    kratos.exp_to_next = flr(kratos.exp_to_next * 1.5)
    sfx(0) -- âm thanh lên cấp
  end
end

-- spawn dong vat --
function spawn_cows()
  cows = {}
  local spawned = 0
  for tx = 0, 127 do
    for ty = 0, 31 do
      local tid = mget(tx, ty)
      if tid == 86 and spawned < 3 then
        add(cows, {
          x = tx * 8,
          y = ty * 8,
          home_x = tx * 8,
          dx = 0.2 * (rnd(1) < 0.5 and -1 or 1),
          anim = 0,
          anim_timer = 0,
          facing = 1,
          move_timer = 0,
          state = "walk",
          attack_phase = 0,
          idle_timer = 0
        })
        spawned += 1
      end
    end
  end
end

function get_zone()
 local tx = flr(kratos.x / 8)
 local ty = flr(kratos.y / 8)

 if tx >= 25 and tx <= 40 and ty >= 25 and ty <= 40 then
  return 1
 elseif tx >= 41 and tx <= 56 and ty >= 25 and ty <= 40 then
  return 2
 elseif tx >= 25 and tx <= 40 and ty >= 41 and ty <= 56 then
  return 3
 else
  return 0 -- ngoれきi zone
 end
end

function spawn_monsters()
  monsters = {}
  local spawned = 0
  for tx = 0, 127 do
    for ty = 0, 31 do
      local tid = mget(tx, ty)
      if tid == 87 and spawned < 5 then
        add(monsters, {
          last_hit_id = -1,
          x = tx * 8,
          y = ty * 8,
          dx = 0.5 * (rnd(1) < 0.5 and -1 or 1),
          w = 8,
          h = 8,
          anim = 0,
          anim_timer = 0,
          facing = 1,
          state = "walk",
          move_timer = 0,
          jump_cooldown = 0,
          idle_timer = 0,
          hp = 5,
          max_hp = 5
        })
        spawned += 1
      end
    end
  end
end


function update_cows()
  for c in all(cows) do
    c.dy = c.dy or 0
    c.dy += 0.2
    if c.dy > 1.5 then c.dy = 1.5 end

    if not solid_at(c.x + 2, c.y + 8) and not solid_at(c.x + 6, c.y + 8) then
      c.y += c.dy
    else
      c.dy = 0
      c.y = flr((c.y + 8) / 8) * 8 - 8
    end
    if c.state == "walk" then
      local ahead_x = c.x + (c.dx > 0 and 8 or -1)
      local ground_y = c.y + 8
      if solid_at(ahead_x, ground_y) then
        c.x += c.dx
       else

         c.dx = 0
         c.state = "idle"
         c.idle_timer = 0
       end

      c.anim_timer += 1
      if c.anim_timer > 10 then
        c.anim_timer = 0
        c.anim = 1 - c.anim
      end

      if solid_at(c.x + (c.dx > 0 and 8 or -1), c.y + 4) then
        if (c.dx > 0 and c.x < c.home_x) or (c.dx < 0 and c.x > c.home_x) then
          c.dx = 0
          c.state = "idle"
          c.idle_timer = 0
        else
          c.dx = -c.dx
          c.facing *= -1
        end
      end

      c.move_timer += 1
      if c.move_timer > 120 then
        c.move_timer = 0
        if rnd(1) < 0.3 then
          c.state = "idle"
          c.dx = 0
          c.idle_timer = 0
        elseif abs(c.x - c.home_x) > 24 or rnd(1) < 0.5 then
          if (c.dx > 0 and c.x > c.home_x) or (c.dx < 0 and c.x < c.home_x) then
            c.dx = -c.dx
            c.facing *= -1
          end
        end
      end

    elseif c.state == "idle" then
      c.anim = 0
      c.idle_timer += 1
      if c.idle_timer > 90 then
        c.state = "walk"
        local dir = rnd(1) < 0.5 and -1 or 1
        if (dir == -1 and c.x <= c.home_x) or (dir == 1 and c.x >= c.home_x) then
          dir = -dir
        end
        c.dx = 0.2 * dir
        c.facing = dir > 0 and 1 or -1
        c.move_timer = 0
      end
    end
  end
end

function update_monsters()
  for m in all(monsters) do
    if m.pinned then
      m.pin_timer += 1
      m.dx *= 0.9
      m.dy += 0.2
      if m.dy > 2 then m.dy = 2 end
      m.x += m.dx
      if not solid_at(m.x + 2, m.y + 8) and not solid_at(m.x + 6, m.y + 8) then
        m.y += m.dy
      else
        m.dy = 0
        m.y = flr((m.y + 8) / 8) * 8 - 8
      end
      if m.pin_timer > 120 then
        m.pinned = false
        m.dx = 0
        m.dy = 0
      end
      goto continue_monster
    end

    if m.state == "idle" or m.state == "walk" then
      m.jump_cooldown = max(0, m.jump_cooldown - 1)
      if abs(kratos.x - m.x) < 20 and abs(kratos.y - m.y) < 12 and m.dy == 0 and m.jump_cooldown == 0 then
        m.state = "jump_attack"
        m.dy = -3.2
        m.attack_phase = 0
        m.jump_cooldown = 90
      end
    end

    if m.state == "jump_attack" then
      m.dy += 0.2
      if m.dy > 3 then m.dy = 3 end
      m.y += m.dy
      if m.dy > 0 and m.attack_phase == 0 then
        m.attack_phase = 1
      end
      if solid_at(m.x + 2, m.y + m.h) or solid_at(m.x + 6, m.y + m.h) then
        m.y = flr((m.y + m.h) / 8) * 8 - m.h
        m.dy = 0
        m.state = "idle"
        m.idle_timer = 0
        if abs(kratos.x - m.x) < 12 and abs(kratos.y - m.y) < 12 then
          kratos.hp = max(0, kratos.hp - 2)
          camera_shake = 6
          sfx(4)
          add(particles, {x=kratos.x, y=kratos.y, t=0, type="land"})
        end
      end
    end

    m.dy = m.dy or 0
    m.dy += 0.2
    if m.dy > 1.5 then m.dy = 1.5 end
    if not solid_at(m.x + 2, m.y + 8) and not solid_at(m.x + 6, m.y + 8) then
      m.y += m.dy
    else
      m.dy = 0
      m.y = flr((m.y + 8) / 8) * 8 - 8
    end

    local ahead_x = m.x + (m.dx > 0 and 8 or -1)
    local feet_y = m.y + m.h
    if solid_at(ahead_x, feet_y) and not solid_at(ahead_x, feet_y - 8) then
      m.dy = -1.8
    end

    local new_x = m.x + m.dx
    if m.dx > 0 then
      if not solid_at(new_x + m.w, m.y + 2) and not solid_at(new_x + m.w, m.y + 6) then
        m.x = new_x
      else
        m.dx = -m.dx
        m.facing *= -1
      end
    elseif m.dx < 0 then
      if not solid_at(new_x, m.y + 2) and not solid_at(new_x, m.y + 6) then
        m.x = new_x
      else
        m.dx = -m.dx
        m.facing *= -1
      end
    end

    if not solid_at(ahead_x, m.y + 8) then
      m.dx = -m.dx
      m.facing *= -1
    end

    m.anim_timer += 1
    if m.anim_timer > 10 then
      m.anim_timer = 0
      m.anim = 1 - m.anim
    end

    ::continue_monster::
  end
end


function update_particles()
  for p in all(particles) do
    p.t += 1
    if p.t > 20 then
      del(particles, p)
    end
  end
end

function draw_particles()
  for p in all(particles) do
    local frame = p.t \ 7
    local sid
    if p.type == "land" then
      sid = 48 + frame
      spr(sid, p.x, p.y)
    elseif p.type == "hit" then
      -- thay vì pset, vẽ chấm to rõ ràng
      circfill(p.x, p.y, 1, 8)
    else
      sid = 51 + frame
      spr(sid, p.x, p.y)
    end
  end
end

function attach_axe()
 axe.x = kratos.x + kratos.facing * 4
 axe.y = kratos.y
 axe.dx = 0
 axe.dy = 0
 axe.thrown = false
 axe.grounded = false
 axe.recall_delay = 0
 axe.spin_timer = 0
 axe.spin_frame = 0
 can_throw_axe = false
 axe_charge = 0
 axe_charging = false
end

function do_hit_fx(x, y)
  -- hướng bay của rìu: >0 là phải, <0 là trái
  local dir = axe.dx > 0 and -1 or 1

  for i=1,8 do
    -- tốc độ bay của hạt
    local speed = 1.5 + rnd(0.5)
    add(particles, {
      x = x,
      y = y,
      -- dx bay về phía sau
      dx = dir * speed,
      -- dy ngẫu nhiên để tỏa lên/xuống
      dy = rnd(1) - 0.5,
      t = 0,
      type = "hit"
    })
  end
end

function solid_at(x, y)
 local tx = flr(x / 8)
 local ty = flr(y / 8)
 local tid = mget(tx, ty)
 return fget(tid, 0)
end

function add_to_inventory(item_id)
  for i in all(kratos.inventory) do
    if i.id == item_id then
      i.amount += 1
      return
    end
  end
  add(kratos.inventory, {id=item_id, amount=1})
end

-- thれちm hiニめ♥u ニめたng quれくi bニめ⬅️ ろ➡️ニむとp bニむとt mニむくnh khi rれてu bay trれむng
function check_axe_hit_monsters()
  if not axe.thrown or axe.returning then return end

  for m in all(monsters) do
    local hit = abs(axe.x - m.x) < 8 and abs(axe.y - m.y) < 8
    if hit and (m.last_hit_id != axe.id) then
      m.last_hit_id = axe.id
      m.pinned = true
      m.pin_timer = 0
      m.dx = axe.dx * 0.6
      m.dy = axe.dy * 0.6
      camera_shake = 8
    end
  end
end


function check_axe_push()
  if not axe.thrown then return end

  -- ghim rれてu vれきo quれくi nニむよu trれむng
  for m in all(monsters) do
    local dx = abs(axe.x - m.x)
    local dy = abs(axe.y - m.y)
    if dx < 6 and dy < 6 and not m.pinned then
      m.dx = axe.dx * 0.8
      m.dy = axe.dy * 0.5
      m.hp = (m.hp or 2) - axe.damage
      do_hit_fx(m.x,m.y)
      if m.hp <= 0 then
        gain_exp(3)
        del(monsters, m)
      end
      sfx(5)
      -- tạo hiệu ứng khi rìu trúng quái
      add(particles, {
        x = m.x + 4,
        y = m.y + 4,
        t = 0,
        type = "hit"
      })
    end
  end
end

function _init()
 spawn_cows()
 spawn_monsters()
 attach_axe()
end

function _update()
 update_cows()
 update_monsters()
 check_axe_push()
 check_axe_hit_monsters()
 wind_time += 0.01
 wind_power = sin(wind_time) * 1.5

 if btnp(2) and kratos.carrying == nil then
   for c in all(cows) do
     if abs(kratos.x - c.x) < 8 and abs(kratos.y - c.y) < 8 then
       kratos.carrying = c
       del(cows, c)
       break
     end
   end
 elseif btnp(2) and kratos.carrying then
   -- thニむこ bれの ra
   kratos.carrying.x = kratos.x
   kratos.carrying.y = kratos.y - 8
   add(cows, kratos.carrying)
   kratos.carrying = nil
 end
 
 -- giニめに lニむくi dx nニむよu ろ➡️ang bニめ⬅️ ろ➡️ニむたy
 if kratos.knockback_timer > 0 then
   kratos.knockback_timer -= 1
   kratos.dx = 0
 end

 local input_dx = 0
 if btn(0) then input_dx = -1 kratos.facing = -1 end
 if btn(1) then input_dx = 1 kratos.facing = 1 end

 if kratos.knockback_timer == 0 then
   if kratos.wall_jump_lock == 0 then
     if kratos.on_ground then
       kratos.dx = input_dx
     else
       -- di chuyển yếu hơn trong không khí
       kratos.dx += input_dx * 0.2
       kratos.dx = mid(-1.2, kratos.dx, 1.2)
     end
   end
 end

 local new_x = kratos.x + kratos.dx
if kratos.dx < 0 then
  if not solid_at(new_x, kratos.y + 2) and not solid_at(new_x, kratos.y + 6) then
    kratos.x = new_x
  end
elseif kratos.dx > 0 then
  if not solid_at(new_x + kratos.w, kratos.y + 2) and not solid_at(new_x + kratos.w, kratos.y + 6) then
    kratos.x = new_x
  end
end

 kratos.dy += 0.4
 if kratos.dy > 3 then kratos.dy = 3 end

 local new_y = kratos.y + kratos.dy
 if kratos.dy > 0 and (solid_at(kratos.x+2, new_y+8) or solid_at(kratos.x+6, new_y+8)) then
  kratos.y = flr((new_y+8)/8)*8 - 8
  kratos.dy = 0
  kratos.on_ground = true
   -- tニむくo bニめしi khi tiニむよp ろ➡️ニむしt
 if not kratos._was_on_ground then
   add(particles, {
     x = kratos.x + 0,
     y = kratos.y + 0,
     t = 0,
     type = "land"
   })
   sfx(4) -- phat am thanh tiep dat 
 end


  kratos.wall_slide = false

  -- nhảy khi đứng đất (bị thiếu)
 if btnp(4) and kratos.on_ground and kratos.samira >= 40 then
   kratos.dy = -3.8
   kratos.samira -= 10
   sfx(1)
   add(particles, {x=kratos.x+4, y=kratos.y+7, t=0, type="jump"})
 end

 elseif kratos.dy < 0 and (solid_at(kratos.x+2, new_y) or solid_at(kratos.x+6, new_y)) then
  kratos.dy = 0
 else
  kratos.y = new_y
  kratos.on_ground = false
  local left_wall = solid_at(kratos.x - 1, kratos.y + 4)
  local right_wall = solid_at(kratos.x + kratos.w + 1, kratos.y + 4)
  kratos.wall_slide = not kratos.on_ground and kratos.dy > 0 and (left_wall or right_wall)
  if kratos.wall_slide then
    kratos.dy = 0.15
  end
 end

 -- xử lý nhảy chuẩn theo Celeste/Hollow Knight
 if btnp(4) and not kratos.on_ground and kratos.wall_slide and kratos.wall_jump_lock == 0 and kratos.samira >= 40 then
   local left_wall = solid_at(kratos.x - 1, kratos.y + 4)
   local right_wall = solid_at(kratos.x + kratos.w + 1, kratos.y + 4)
   kratos.samira -= 20

   if left_wall then
     kratos.dy = -3.8
     kratos.dx = 1.8
     kratos.wall_jump_lock = 10
     sfx(1)
     add(particles, {x=kratos.x+4, y=kratos.y+7, t=0, type="jump"})
   elseif right_wall then
     kratos.dy = -3.8
     kratos.dx = -1.8
     kratos.wall_jump_lock = 10
     sfx(1)
     add(particles, {x=kratos.x+4, y=kratos.y+7, t=0, type="jump"})
   end
 end

-- giニめに nguyれちn phニむせn cれのn lニむくi


 if btn(5) and not axe.thrown and can_throw_axe then
  axe_charge = min(axe_charge + 1, axe_max_charge)
  axe_charging = true
  -- 👇 Giảm samira khi tụ lực
  kratos.samira = max(0, kratos.samira - 1)
 elseif axe_charging then
   if axe_charge < axe_max_charge * 0.3 then
     -- Đánh thường tầm gần thay vì ném rìu
     for m in all(monsters) do
       if abs(kratos.x - m.x) < 10 and abs(kratos.y - m.y) < 8 then
         m.hp = (m.hp or 2) - 1
         sfx(5)
         if m.hp <= 0 then
           gain_exp(3)
           del(monsters, m)
         end
         camera_shake = 4
       end
     end
     -- reset trạng thái charge
     axe_charge = 0
     axe_charging = false
   else
     -- Ném rìu như thường lệ
     axe.id += 1
     axe.thrown = true
     axe.returning = false
     axe.grounded = false
     axe.x = kratos.x + kratos.facing * 10
     axe.y = kratos.y - 2
     local speed_factor = axe_charge / axe_max_charge
     axe.dx = kratos.facing * axe.speed * (0.5 + 0.5 * speed_factor)
     axe.dy = -1 * speed_factor
     axe.recall_delay = 8
     can_throw_axe = false
     axe_charge = 0
     axe_charging = false
     sfx(3)
   end
 end 

 if btnp(5) and axe.thrown and not axe.returning then
   axe.want_to_recall = true
 end



 if axe.recall_delay > 0 then
   axe.recall_delay -= 1
 end


 if axe.thrown and axe.want_to_recall and axe.recall_delay <= 0 and not axe.returning then
   axe.returning = true
   axe.grounded = false
   axe.want_to_recall = false
   camera_shake = 8
 end



 if axe.thrown then
  if not axe.grounded and not axe.returning then
   axe.dy += 0.2
   if axe.dy > 2 then axe.dy = 2 end
   axe.x += axe.dx
   axe.y += axe.dy

   if solid_at(axe.x+4, axe.y+8) then
    axe.y = flr((axe.y+8)/8)*8 - 5
    axe.dx = 0
    axe.dy = 0
    if not axe.grounded and camera_shake == 0 then
      camera_shake = 8
    end
    axe.grounded = true
    add(particles, {
      x = axe.x,
      y = axe.y - 3,
      t = 0,
      type = "land"
    })
    sfx(4)
   end

  elseif axe.returning then
   local dx = kratos.x - axe.x
   local dy = kratos.y - axe.y
   local dist = sqrt(dx*dx + dy*dy)
   local spd = axe.speed

   axe.dx = (dx / dist) * spd
   axe.dy = (dy / dist) * spd

   axe.x += axe.dx
   axe.y += axe.dy

   if dist < 6 then
    attach_axe()
    camera_shake = 8
   end
  end

  if not axe.grounded or axe.returning then
   axe.spin_timer += 1
   if axe.spin_timer > 1 then
    axe.spin_timer = 0
    axe.spin_frame = (axe.spin_frame + 1) % 4
   end
  end
 else
  axe.x = kratos.x + kratos.facing * 4
  axe.y = kratos.y
 end


 if not kratos.on_ground then
  kratos.state = "jump"
 elseif axe.thrown and axe.recall_delay > 10 then
  kratos.state = "throw"
 elseif kratos.dx != 0 then
  kratos.state = "run"
 else
  kratos.state = "idle"
 end

 kratos.anim_timer += 1
 if kratos.state == "run" then
  if kratos.anim_timer > 6 then
   kratos.anim_timer = 0
   kratos.anim_frame = (kratos.anim_frame + 1) % 2
  end
 elseif kratos.state == "idle" then
   if kratos.anim_timer > 30 then
     kratos.anim_timer = 0
     kratos.anim_frame = (kratos.anim_frame + 1) % 2
   end
 elseif kratos.state == "throw" then
   kratos.anim_frame = 0
   kratos.anim_timer = 0
 end

 if not btn(5) then
  can_throw_axe = true
 end

 kratos._was_on_ground = kratos.on_ground

 update_particles()

 if kratos.wall_jump_lock > 0 then
   kratos.wall_jump_lock -= 1
 end

 -- ✨ Thêm đoạn này bên dưới:
 if kratos.wall_jump_lock > 0 then
   if kratos.dx > 0 then
     kratos.dx = max(kratos.dx - 0.1, 0.5)
   elseif kratos.dx < 0 then
     kratos.dx = min(kratos.dx + 0.1, -0.5)
   end
 end
 -- hồi samira theo thời gian
 kratos.samira = min(kratos.samira + 0.2, kratos.max_samira)

end

function is_grass_tile(id) --id co 
  return id == 70 or id == 86 or id == 165 or id == 131 or id == 130 or id == 54 or id == 56
end

function is_water_tile(id)
  return id == 181
end

function draw_swaying_grass(x, y, t, tile_id)
  local base_x = (tile_id % 16) * 8
  local base_y = flr(tile_id / 16) * 8

  -- sれはng sin cをく bニむこn theo thニめえi gian vれき vニめ⬅️ trれと x
  local sway_base = sin(t * 0.2 + x * 0.1) * 1.5

  for row = 0, 5 do
    -- thれちm biニむよn thニめ⬇️ nhニめ◆ theo tニめつng dれのng ろ➡️ニめ⬇️ tニむくo cニむこm giれくc "rung lニむにc"
    local offset = flr(sway_base + sin(t * 0.7 + row * 0.3) * 0.5)
    sspr(base_x, base_y + row, 8, 1, x + offset, y + row)
  end

  -- phニむせn gニめ➡️c khれひng bニめ⬅️ lニめ♥ch
  sspr(base_x, base_y + 6, 8, 2, x, y + 6)
end

function _draw()
  cls()

  -- hiニめ♥u ニめたng れくnh sれくng quanh rれてu khi tニめし lニめねc ろ➡️ニむせy
  if not axe.thrown and axe_charge == axe_max_charge then
    local cx = axe.x + 4
    local cy = axe.y + 4
    for i=1,10 do
      local a = time() + i * 0.3
      local r = (time() % 1) * 6
      local rx = cx + cos(a) * r
      local ry = cy + sin(a) * r
      local col = (r < 4) and 7 or 5
      pset(rx, ry, col)
    end
  end

  -- thanh lニめねc khi tニめし rれてu
  if axe_charging then
    local bar_x = kratos.x
    local bar_y = kratos.y - 4
    local bar_w = 8
    local bar_h = 1
    local filled_w = flr((axe_charge / axe_max_charge) * bar_w)

    rectfill(bar_x, bar_y, bar_x + bar_w - 1, bar_y + bar_h, 1)
    local c = 10
    if axe_charge >= axe_max_charge and (time() % 0.2 < 0.1) then
      c = 7
    end
    rectfill(bar_x, bar_y, bar_x + filled_w - 1, bar_y + bar_h, c)
  end

  -- camera vれき rung
  -- xれくc ろ➡️ニめ⬅️nh zone hiニめ♥n tニむくi (mニめ❎i zone 128x128 pixel = 16x16 tiles)
  local zone_x = flr(kratos.x / 128)
  local zone_y = flr(kratos.y / 128)

  local zx = zone_x * 128
  local zy = zone_y * 128

  local cam_x = mid(zx, kratos.x - 64, zx + 128 - 128)
  local cam_y = mid(zy, kratos.y - 64, zy + 128 - 128)

  if camera_shake > 0 then
    camera_shake -= 1
    camera(cam_x + rnd(3) - 1.5, cam_y + rnd(3) - 1.5)
  else
    camera(cam_x, cam_y)
  end

  -- ve thanh mau 
  local hp_bar_x = cam_x + 4
  local hp_bar_y = cam_y + 4
  local hp_bar_w = 30
  local hp_fill = flr((kratos.hp / kratos.max_hp) * hp_bar_w)
  rect(hp_bar_x - 1, hp_bar_y - 1, hp_bar_x + hp_bar_w, hp_bar_y + 4, 5)
  rectfill(hp_bar_x, hp_bar_y, hp_bar_x + hp_bar_w - 1, hp_bar_y + 3, 2)
  rectfill(hp_bar_x, hp_bar_y, hp_bar_x + hp_fill - 1, hp_bar_y + 3, 8)
  print("lv "..kratos.level, hp_bar_x, hp_bar_y + 13, 11)
  -- thanh samira (dưới thanh máu)
  local samira_bar_y = hp_bar_y + 6
  local samira_fill = flr((kratos.samira / kratos.max_samira) * hp_bar_w)
  rect(hp_bar_x - 1, samira_bar_y - 1, hp_bar_x + hp_bar_w, samira_bar_y + 4, 5) -- viền
  rectfill(hp_bar_x, samira_bar_y, hp_bar_x + hp_bar_w - 1, samira_bar_y + 3, 1) -- nền đen
  rectfill(hp_bar_x, samira_bar_y, hp_bar_x + samira_fill - 1, samira_bar_y + 3, 11) -- màu hồng

  -- vニむや map (gom nニめ▒n + cニめ◆)
  local cam_tx = flr(cam_x / 8)
  local cam_ty = flr(cam_y / 8)

  -- camera 64x64
  for tx = cam_tx, cam_tx + 16 do
    for ty = cam_ty, cam_ty + 16 do
      local tid = mget(tx, ty)
      local draw_x = tx * 8
      local draw_y = ty * 8
      if is_water_tile(tid) then
        spr(tid, draw_x, draw_y)
      elseif is_grass_tile(tid) then
        draw_swaying_grass(draw_x, draw_y, time(), tid)
      else
        spr(tid, draw_x, draw_y)
      end
    end
  end

  -- vニむや kratos
  local sid = 1
  if kratos.wall_slide then
    sid = 9
  elseif kratos.state == "run" then
    sid = 2 + kratos.anim_frame
  elseif kratos.state == "throw" then
    sid = 4
  elseif kratos.state == "idle" then
    sid = kratos.anim_frame == 0 and 1 or 10
  elseif kratos.state == "jump" then
    if kratos.dy < -1 then sid = 5
    elseif kratos.dy > 1 then sid = 7
    else sid = 6 end
  end
  spr(sid, kratos.x, kratos.y, 1, 1, kratos.facing == -1)

  if kratos.carrying then
    spr(37, kratos.x, kratos.y - 8)
  end

  -- vニむや bれの
  for c in all(cows) do
    local sid
    if c.state == "idle" then
      sid = 37
    else
      sid = c.anim == 0 and 38 or 39
    end
    spr(sid, c.x, c.y, 1, 1, c.facing == -1)
  end

  -- vニむや rれてu
  local axe_sprites = {16,17,18,19}
  if axe.thrown then
    for i=1,4 do
      local trail_x = axe.x - axe.dx * i
      local trail_y = axe.y - axe.dy * i
      pset(trail_x + 4, trail_y + 4, 7)
    end
    spr(axe_sprites[axe.spin_frame+1], axe.x, axe.y, 1, 1, (not axe.grounded and axe.thrown) and kratos.facing == -1)
  else
    spr(16, axe.x, axe.y, 1, 1, not axe.thrown and kratos.facing == -1)
  end

  -- vニむや quれくi
  for m in all(monsters) do
    local sid
    if m.pinned then
      sid = 42
    else
      sid = m.anim == 0 and 40 or 41
    end
    spr(sid, m.x, m.y, 1, 1, m.facing == -1)
    -- hp bar
    if m.hp and m.max_hp and m.hp < m.max_hp then
      local bar_w = 8
      local bar_h = 1
      local fill_w = flr((m.hp / m.max_hp) * bar_w)
      rectfill(m.x, m.y - 2, m.x + bar_w - 1, m.y - 2 + bar_h, 1) -- nền đen
      rectfill(m.x, m.y - 2, m.x + fill_w - 1, m.y - 2 + bar_h, 8) -- máu còn lại (xanh)
    end
  end

  if show_inventory then
    local inv_x = cam_x + 80
    local inv_y = cam_y + 10
    rectfill(inv_x - 2, inv_y - 6, inv_x + 44, inv_y + #kratos.inventory * 6 + 4, 1)
    rect(inv_x - 3, inv_y - 7, inv_x + 45, inv_y + #kratos.inventory * 6 + 5, 6)
    --spr(137, inv_x - 20, inv_y - 10)
  
    for i, item in ipairs(kratos.inventory) do
      print(item.id..":"..item.amount, inv_x, inv_y + i*6, 7)
    end
  end
  -- hiện bảng trạng thái khi ấn xuống
  if btn(3) then
    -- nhấn xuống để bật/tắt hiển thị thống kê
    if btnp(3) then
      show_stats = not show_stats
    end
    local stat_x = cam_x + 4
    local stat_y = cam_y + 20
    rectfill(stat_x - 2, stat_y - 2, stat_x + 60, stat_y + 30, 1)
    rect(stat_x - 3, stat_y - 3, stat_x + 61, stat_y + 31, 7)

    print("Kratos", stat_x, stat_y, 7)
    print("exp: "..kratos.exp.."/"..kratos.exp_to_next, stat_x, stat_y + 8, 6)
    print("hp: "..kratos.hp.."/"..kratos.max_hp, stat_x, stat_y + 14, 11)
    print("Dame Axe: 1", stat_x, stat_y + 20, 10)
  end

  -- hiển thị cpu / fps / ram
  if show_stats then
    local cpu = stat(1)
    local fps = stat(7)
    local ram = stat(0)
    rectfill(cam_x + 60, cam_y + 0, cam_x + 128, cam_y + 24, 0) -- nền đen
    print("cpu:"..flr(cpu*100).."%", cam_x + 60, cam_y + 1, 11)
    print("fps:"..fps, cam_x + 60, cam_y + 9, 11)
    print("ram:"..ram.."/8192", cam_x + 60, cam_y + 17, 11)
  end

  draw_particles()
end