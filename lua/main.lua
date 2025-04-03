_G._DEBUG = false

local mv = require "mv"

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

local decay_A = 0.64478415 
local decay_B = 0.38393326 

local sim_scale     = 60 -- how many 1/n seconds in one frame
local num_sim_ticks = 500 -- how many to frames to simulate

local pad = 16
local t = 0.0
local dt = 0.0
local nval_A = 0.7
local nval_B = 0.2
local Kval   = 0.6

local history_A = {}
local history_B = {}
local history_depth = sim_scale

local function push_history( _t, _v )
    table.insert(_t, 1, _v)
    if #_t > history_depth then
        table.remove(_t, #_t)
    end
end

function love.update(_dt)
    t = t + _dt
    dt = _dt
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

local last_line_pos = nil
local function plot_line(_info)
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

    if last_line_pos ~= nil then
        love.graphics.line(last_line_pos.X, last_line_pos.Y, point_pos.X, point_pos.Y)
    end

    last_line_pos = point_pos
end

local function end_plot_line() 
    last_line_pos = nil
end

local function plot_history(i, _t)
    local i = math.floor( i )
    if i > #_t then return 0 end
    
    return _t[ (#_t+1) - i ] / 70.0
end

local function handle_input()

    local move_speed = 0.1
    if love.keyboard.isDown( "d" ) then
        decay_A = decay_A + dt * move_speed
    end

    if love.keyboard.isDown( "a" ) then
        decay_A = decay_A - dt * move_speed
    end

    if love.keyboard.isDown( "w" ) then
        decay_B = decay_B + dt * move_speed
    end

    if love.keyboard.isDown( "s" ) then
        decay_B = decay_B - dt * move_speed
    end

    if love.keyboard.isDown( "e" ) then
        num_sim_ticks = num_sim_ticks + 20
    end

    if love.keyboard.isDown( "q" ) then
        num_sim_ticks = num_sim_ticks - 20
    end

    num_sim_ticks = math.max( num_sim_ticks, 1 )

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
        format  = "%.2f",
        params  = {
            ["n A"] = nval_A,
            ["n B"] = nval_B,
            ["K"] = Kval,
            ["conc_A"] = conc_A,
            ["conc_B"] = conc_B,
            ["decay_A"] = decay_A,
            ["decay_B"] = decay_B,
            ["ticks"] = num_sim_ticks
        }
    })
    
    love.graphics.setColor(0.5,0.9,0.5)
    mv:plot("line", {
        func       = function(i,k,n) return hill(i,k,n) - decay_A end,
        params     = { Kval, nval_A },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = x_range,
        resolution = 512
    })
    
    love.graphics.setColor(0.9,0.5,0.5)
    mv:plot("line", {
        func       = function(i,k,n) return hill2(i,k,n) - decay_B end,
        params     = { Kval, nval_B },
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
    
    -- decay_A = mathex.lerp( 0.1, 0.7, mathex.sin_norm(t) )
    -- decay_B = mathex.lerp( 0.3, 1.0, mathex.cos_norm(t) )
    
    handle_input()

    love.graphics.setColor(1,1,1,1)
    
    push_history(history_A, conc_A)
    push_history(history_B, conc_B)

    mv:begin_scope(pad+16,pad+16)
    local region2 = mv:frame_xy({
        pos     = vec2(region.position.X + region.size.X + pad + 1, pad),
        size    = vec2(500, 300),
        x_range = { 0, num_sim_ticks / sim_scale },
        --y_range = { 0.0, 1.0 },
        grid    = vec2(4, 10),
        subgrid = vec2(2, 3),
        padding = pad,
        format  = "%.3f",
        params  = {
            ["conc_A"] = conc_A,
            ["conc_B"] = conc_B,
            ["ticks"] = num_sim_ticks
        }
    })
    
    love.graphics.setColor(0.9,0.5,0.5)
    mv:plot("line", {
        func       = plot_history,
        params     = {history_A},
        pos        = region2.plot_position,
        size       = region2.plot_size,
        x_range    = {1, #history_A},
        resolution = #history_A
    })
    
    love.graphics.setColor(0.5,0.9,0.5)
    mv:plot("line", {
        func       = plot_history,
        params     = {history_B},
        pos        = region2.plot_position,
        size       = region2.plot_size,
        x_range    = {1, #history_B},
        resolution = #history_B
    })
    
   
    for i=0,num_sim_ticks do
        local tick_dt = 1/sim_scale

        local delta_A = hill (conc_B, Kval, nval_A) - decay_A
        local delta_B = hill2(conc_A, Kval, nval_B) - decay_B

        conc_A = conc_A + (delta_A * tick_dt)
        conc_B = conc_B + (delta_B * tick_dt)

        conc_A = math.max(conc_A, 0.0)
        conc_B = math.max(conc_B, 0.0)
        
        local halpha = i / num_sim_ticks
        love.graphics.setColor(0.5,0.5,0.9, 1-halpha)
        plot_line({
            point = vec2(conc_A, conc_B),
            pos  = region2.plot_position,
            size = region2.plot_size,
            x_range = {0, 500.0},
            y_range = {0, 40.0}
        })
    end
    end_plot_line()

    for i = 1, #history_A do
    end
    love.graphics.setColor(1,1,1,1)
    mv:end_scope()

    local ww = region.position.X + region.size.X + pad + 1
    local wh = region.position.Y + region.size.Y + pad 

    local ww = ww * 2

    local window_width, window_height = love.window.getMode()
    local resize = window_width ~= ww or window_height ~= wh
    if resize then 
        mv:on_resize(ww,wh)
        love.window.setMode(ww, wh)
    end
end