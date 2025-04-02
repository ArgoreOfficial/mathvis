_G._DEBUG = false

local mv = require "mv"

local function table(_t)
    local count = 0
    for _ in pairs(_t) do count = count + 1 end
    return count
end

-- n = count
-- A = receptor
-- B = ligand molecules
-- K = reaction dissociation constant
-- [X] = concentration of chemical species X

local function hill(B, K, n)
    return (B^n) / (K^n + (B^n))
end

local function hill2(B, K, n)
    return (K^n) / (K^n + (B^n))
end

local function hill_mult(B, K1, n1, K2, n2)
    return hill(B,K1,n1) * hill2(B,K2,n2)
end


function love.load()
	love.graphics.setLineStyle( "rough" )
    love.graphics.setLineWidth( 1 )
    love.window.setTitle( "GeRNS" )
end


local conc_A = 0.0
local conc_B = 0.0

local pad = 16
local t = 0.0
local nval_A = 0.7
local nval_B = 0.2
local Kval =  0.6

local function tick(_dt)
    local delta_a = hill (conc_B, 0.6, nval_A) - 0.3
    local delta_b = hill2(conc_A, 0.6, nval_B) - conc_A

    conc_A = conc_A + (delta_a * _dt)
    conc_B = conc_B + (delta_b * _dt)

    conc_A = math.max(conc_A, 0.0)
    conc_B = math.max(conc_B, 0.0)
end

function love.update(_dt)
    t = t + _dt
    --nval = mathex.sin_norm(t) * 14.0 + 1.0
    --Kval = mathex.lerp(0.1, 4.8, mathex.sin_norm(t))
end


local function range_to_range(_range1, _range2, _value)
    local start_1, end_1 = unpack( _range1 )
    local start_2, end_2 = unpack( _range2 )

    return mathex.lerp(
        start_2, 
        end_2, 
        (_value - start_1) / (end_1 - start_1))
end

local function plot_line_y(_info)
    local value = _info.value or 0.5
    local pos = _info.pos or vec2(0,0)
    local size = _info.size or vec2(256,256)
    local x_range = _info.x_range or {0.0, 1.0}
    
    local normalized = range_to_range(x_range, {0.0, 1.0}, value)
    if normalized > 1.0 then return end
    if normalized < 0.0 then return end

    local line_x = pos.X + normalized * (size.X)
    love.graphics.line(line_x, pos.Y, line_x, pos.Y + size.Y)

    if _info.format then 
        local half_y = mathex.lerp(pos.Y, pos.Y + size.Y, 0.5)
        local str = string.format(_info.format, value)
        --love.graphics.print(str, math.floor(line_x) + 2, math.floor(half_y))
        local str_height = love.graphics.getFont():getHeight(str)
        mv:text_centre( str, math.floor(line_x), math.floor(pos.Y) - str_height/2 )
    end
end

local function plot_point(_info)
    local point = _info.point or vec2(0,0)
    local pos = _info.pos or vec2(0,0)
    local size = _info.size or vec2(256,256)
    local x_range = _info.x_range or {0.0, 1.0}
    local y_range = _info.y_range or {0.0, 1.0}

    local norm_x = range_to_range(x_range, {0.0, 1.0}, point.X)
    local norm_y = range_to_range(y_range, {0.0, 1.0}, point.Y)
    
    local point_pos = vec2(
        mathex.lerp(pos.X, pos.X + size.X, norm_x),
        mathex.lerp(pos.Y + size.Y, pos.Y, norm_y)
    )

    love.graphics.circle("fill", point_pos.X, point_pos.Y, 1)
end

function love.draw()
    love.graphics.clear()
    love.graphics.setColor(1,1,1,1)
    
    local x_range = {0.0, 3.0}
    mv:begin_scope(pad+16,pad+16)
    local region = mv:frame_xy({
        pos     = vec2(pad, pad),
        size    = vec2(500, 300),
        x_range = x_range,
        y_range = { 0.0, 1.0 },
        grid    = vec2(11, 10),
        subgrid = vec2(6, 3),
        padding = pad,
        params  = {
            ["n A"] = nval_A,
            ["n B"] = nval_B,
            ["K"] = Kval
        }
    })
    
    love.graphics.setColor(0.5,0.9,0.5)
    mv:plot("line", {
        func       = hill,
        params     = { Kval, 0.7 },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = x_range,
        resolution = 512
    })
    
    love.graphics.setColor(0.9,0.5,0.5)
    mv:plot("line", {
        func       = hill2,
        params     = { Kval, 0.3 },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = x_range,
        resolution = 512
    })
    
    local tree = mv:end_scope()
    --mv:display_scopes( tree )
    
    if false then
        love.graphics.setColor(0.5,0.9,0.5)
        plot_line_y({
            value = conc_A,
            pos = region.plot_position,
            size = region.plot_size,
            x_range = x_range,
            format = "%.2f"
        })
    
        love.graphics.setColor(0.9,0.5,0.5)
        plot_line_y({
            value = conc_B,
            pos = region.plot_position,
            size = region.plot_size,
            x_range = x_range,
            format = "%.2f"
        })
    end
    
    love.graphics.setColor(0.5,0.5,0.9, 1.0)

    local num_frames = 100

    for i=0,num_frames do
        tick(1/120)
        plot_point({
            point = vec2(conc_A, conc_B),
            pos = region.plot_position,
            size = region.plot_size,
            x_range = {0, 3},
            y_range = {0, 1}
        })
    end

    local ww = region.position.X + region.size.X + pad + 1
    local wh = region.position.Y + region.size.Y + pad 
    local window_width, window_height = love.window.getMode()
    local resize = window_width ~= ww or window_height ~= wh
    if resize then 
        mv:on_resize(ww,wh)
        love.window.setMode(ww, wh)
    end
end