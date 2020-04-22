_addon.version = '0.0.1'
_addon.name = 'lostandfound'
_addon.author = 'yyoshisaur'
_addon.commands = {'lostandfound'}

require('luau')
require('chat')
local packets = require('packets')
local texts = require('texts')

odys_box = texts.new('${info}',{text={font='Consolas', size=12}, pos={x=200, y=200}, padding = 5, bg={alpha=125,}})

local track_mob_names = S{'???',}
local track_zone = S{55}
local dead_statuses = S{2, 3} -- Dead, Engaged Dead
local expend_mob_ids = S{}

local clue_indexes = S{177, 178, 179}
local eye_of_zahak_index = S{176}

local function get_string_for_display(me, mob)
    local t = windower.ffxi.get_mob_by_target('t')
    local angle = calc_standard_angle(mob.x, mob.y, me.x, me.y)
    local direction = angle_to_direction(angle)
    local distance = math.sqrt(mob.distance)

    if not dead_statuses:contains(mob.status) and not expend_mob_ids:contains(mob.id) then
        local info = ''
        if distance < 50 then
            info = '%3s (%4.1f) %s':format(direction, math.sqrt(mob.distance), mob.name)
        else
            info = '%3s        %s':format(direction, mob.name)
        end

        if clue_indexes:contains(mob.index) then
            info = info..' (Clue)'
        elseif eye_of_zahak_index:contains(mob.index) then
            info = info..' (Eye Of Zahak)'
        end

        if t and t.id == mob.id then
            info = string.text_color(info,255,0,0)
        end
        return info
    end
    return nil
end

windower.register_event('prerender', function()
    local me = windower.ffxi.get_mob_by_target('me')
    local zone = windower.ffxi.get_info().zone

    if not me or not track_zone:contains(zone) then
        odys_box:visible(false)
        return
    end

    local mob_array = windower.ffxi.get_mob_array()
    local lines = L{}
    for _, mob in pairs(mob_array) do
        for track_mob_name in track_mob_names:it() do
            if windower.wc_match(mob.name, track_mob_name) then
                local line_str = get_string_for_display(me, mob)
                if line_str then
                    lines:append(line_str)
                end
            end
        end
    end
    if lines:length() > 0 then
        lines:insert(1, 'Lost and Found ??? Tracker')
        lines:insert(2, string.text_color('Dir  Dist  Name', 255, 255,0))
        odys_box.info = lines:concat('\n')
        odys_box:visible(true)
    else
        odys_box:visible(false)
    end
end)

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
    if id == 0x01A then
        local p = packets.parse('outgoing', original)
        if p['Category'] == 0x00 then
            local t = windower.ffxi.get_mob_by_id(p['Target'])
            if track_mob_names:contains(t.name) then
                expend_mob_ids:add(t.id)
                log('poke '..t.name..' '..t.index)
            end
        end
    end
end)

windower.register_event('zone change', function()
    expend_mob_ids = S{}
end)

windower.register_event('logout', function()
    expend_mob_ids = S{}
end)

-- Credit: MobCompass v1.0
function calc_standard_angle(Px, Py, Mx, My)

    local angle = 0
    local Px = tonumber(Px)
    local Py = tonumber(Py)
    local Mx = tonumber(Mx)
    local My = tonumber(My)

    local PM = (Px - Mx) / (Py - My)
    local PM_angle = math.atan(PM) * 180/math.pi

    if (Px > Mx) and (Py > My) then
        angle = PM_angle 
    elseif (Px > Mx) and (Py < My) then
        angle = 180 + PM_angle 
    elseif (Px < Mx) and (Py < My) then
        angle = 180 + PM_angle
    elseif (Px < Mx) and (Py > My) then
        angle = 360 + PM_angle 
    elseif (Px == Mx) and (Py < My) then
        angle = 0
    elseif (Px > Mx) and (Py == My) then
        angle = 90
    elseif (Px == Mx) and (Py > My) then
        angle = 180
    elseif (Px < Mx) and (Py == My) then
        angle = 270
    end

    if angle ~= nil then 
        return angle:round(1)
    end
end

function angle_to_direction(angle)

    local angle = tonumber(angle)
    local direction = ''

    if (angle <= 11.25) and (angle >= 0) then
        direction = 'N'
    elseif angle <= 360 and angle > (11.25 * 31) then
        direction = 'N'
    elseif angle <= (11.25 * 3) and angle > 11.25 then
        direction = 'NNE'
    elseif angle <= (11.25 * 5) and angle > (11.25 * 3) then
        direction = 'NE'
    elseif angle <= (11.25 * 7) and angle > (11.25 * 5) then
        direction = 'NEE'
    elseif angle <= (11.25 * 9) and angle > (11.25 * 7) then
        direction = 'E'
    elseif angle <= (11.25 * 11) and angle > (11.25 * 9) then
        direction = 'SEE'
    elseif angle <= (11.25 * 13) and angle > (11.25 * 11) then
        direction = 'SE'
    elseif angle <= (11.25 * 15) and angle > (11.25 * 13) then
        direction = 'SSE'
    elseif angle <= (11.25 * 17) and angle > (11.25 * 15) then
        direction = 'S'
    elseif angle <= (11.25 * 19) and angle > (11.25 * 17) then
        direction = 'SSW'
    elseif angle <= (11.25 * 21) and angle > (11.25 * 19) then
        direction = 'SW'
    elseif angle <= (11.25 * 23) and angle > (11.25 * 21) then
        direction = 'SWW'
    elseif angle <= (11.25 * 25) and angle > (11.25 * 23) then
        direction = 'W'
    elseif angle <= (11.25 * 27) and angle > (11.25 * 25) then
        direction = 'NWW'
    elseif angle <= (11.25 * 29) and angle > (11.25 * 27) then
        direction = 'NW'
    elseif angle <= (11.25 * 31) and angle > (11.25 * 29) then
        direction = 'NNW'
    end

    return tostring(direction)	
end