
require "mv_math"
local mv = require "mv"

local function draw_graph(_t, _x, _y, _width, _height )

    if #_t < 2 then return end

    local function _get_y(_v) return _y + _height - _v * _height end

    local last_x = _x
    local last_y = _get_y(_t[1])
    local cell_size = _width / (#_t-1)

    for i=2, #_t do
        local x = _x + (i - 1) * cell_size
        
        local y = _get_y(_t[i])

        love.graphics.line(last_x, last_y, x, y)

        last_x = x
        last_y = y
    end
end

local function draw_segments_x( _x_min, _x_max, _y, _v, _height, _margin, _str )
    local x = lerp( _x_min, _x_max, _v )
    love.graphics.line( x, _y, x, _y - _height )

    if _str then
        draw_text_top(_str, x, _y + _margin )
    end
end

local function draw_segments_y( _y_min, _y_max, _x, _v, _width, _margin, _str )
    local y = lerp( _y_min, _y_max, _v )
    love.graphics.line( _x, y, _x + _width, y )

    if _str then
        draw_text_right(_str, _x - _margin, y )
    end
end

local function table_length(_t)
    local count = 0
    for _ in pairs(_t) do count = count + 1 end
    return count
end

local function frame_xy( _info )
    local pos     = _info.pos     or { 16,   16 }
    local size    = _info.size    or { 256, 256 }
    local x_range = _info.x_range or { 0.0, 3.0 }
    local y_range = _info.y_range or { 0.0, 1.0 }
    local padding = _info.padding or 0
    local margin  = _info.margin  or 5
    local params  = _info.params  or { }
    local grid    = _info.grid    or { 6, 6 }
    local subgrid = _info.subgrid or { 6, 6 }

    local segs_x = grid[1] or 0
    local segs_y = grid[2] or 0
    
    local sub_segs_x = subgrid[1] or 0
    local sub_segs_y = subgrid[2] or 0
    
    local text_width  = love.graphics.getFont():getWidth("0.00")
    local text_height = love.graphics.getFont():getHeight("0.00")

    local offset_x = padding + margin + text_width
    local offset_y = padding 

    local posx = (pos[1] or 0) + offset_x
    local posy = (pos[2] or 0) + offset_y
    local width  = size[1] or 256
    local height = size[2] or 256

    local left   = posx - padding
    local top    = posy - padding
    local right  = left + width  + padding*2
    local bottom = top  + height + padding*2

    local regions = {
        position = {pos[1] or 0, pos[2] or 0},
        size = {
            width + padding + offset_x, 
            height + padding*2 + margin + (text_height * (table_length(params) + 1))
        },

        plot_position = {left + padding, top + padding},
        plot_size     = {width, height}
    }

    love.graphics.rectangle( 
        "line", 
        left,   top+2, 
        width + padding*2 - 2, height + padding*2 - 2)

    mv:ruler({
        pos_a=vec2(posx,bottom),
        pos_b=vec2(posx+width,bottom), 
        num_marks = segs_x, 
        num_submarks = sub_segs_x, 
        mark_length = 8, 
        submark_length = 5,
        text_format = "%.2f", 
        text_range = x_range,
        flip = false
    })

    mv:ruler({
        pos_a=vec2(left,posy+height),
        pos_b=vec2(left,posy), 
        num_marks = segs_y, 
        num_submarks = sub_segs_y, 
        mark_length = 8, 
        submark_length = 5,
        text_format = "%.2f", 
        text_range = y_range,
        flip = true
    })

    local param_offset = 1
    for i, v in pairs(params) do
        local str = i .. "=" .. tostring(v)
        local text_height = love.graphics.getFont():getHeight(str)
        love.graphics.print(str, posx, bottom + (param_offset * text_height) + 5)
        param_offset = param_offset + 1
    end

    return regions
end

local function sin_norm(_v) 
    return math.sin(_v) * 0.5 + 0.5
end

local function cos_norm(_v) 
    return math.cos(_v) * 0.5 + 0.5
end

local function clamp(_v, _min, _max)
    return math.max( math.min( _v, _max ), _min )
end

function plot_func( _info )
    local func       = _info.func
    local params     = _info.params     or { }
    local pos        = _info.pos        or {   0,   0 }
    local size       = _info.size       or { 300, 100 }
    local resolution = _info.resolution or size[1]
    local x_range      = _info.x_range      or { 0.0, 1.0 }
    
    local pos_x  = pos[1]
    local pos_y  = pos[2]
    
    local width  = size[1]
    local height = size[2]

    local x_range_min = x_range[1]
    local x_range_max = x_range[2]

    local px_w = width - 1
    local px_h = height - 1
    
    local data = love.image.newImageData(width,height)
    
    for i=x_range_min, resolution do
        local xval = (i / resolution) * x_range_max
        local v = func( xval, unpack(params) )

        local x = (xval / x_range_max) * px_w
        local y = px_h - (v * px_h)

        local in_x_range = (x >= 0 and x < width)
        local in_y_range = (y >= 0 and y < height)

        if in_x_range and in_y_range then
            data:setPixel(x,y,1,1,1,1)
        end
    end
    
    local image = love.graphics.newImage(data)
    love.graphics.draw(image, pos_x, pos_y)
end

function plot_func_line( _info )
    local func       = _info.func
    local params     = _info.params     or { }
    local pos        = _info.pos        or {   0,   0 }
    local size       = _info.size       or { 300, 100 }
    local resolution = _info.resolution or size[1]
    local x_range    = _info.x_range    or { 0.0, 1.0 }
    
    local pos_x,pos_y  = pos[1] or 0, pos[2] or 0
    local width,height = size[1] or 256, size[2] or 256
    local x_range_min,x_range_max = x_range[1] or 0.0, x_range[2] or 1.0
    
    local px_w = width - 1
    local px_h = height - 1

    local function x_of(_v) return lerp(pos_x, pos_x + px_w, _v) end
    local function y_of(_v) return pos_y + px_h - (_v * px_h) end

    local real_t = lerp(x_range_min, x_range_max, 0)
    local last_v = func(real_t, unpack(params))
    for i=1, resolution do
        local t = (i / resolution)
        local last_t = ((i-1) / resolution)
        real_t = lerp(x_range_min, x_range_max, t)
        local v = func(real_t, unpack(params))
        
        local x = x_of(t)
        local y = y_of(v)
        local last_x = x_of(last_t)
        local last_y = y_of(last_v)

        love.graphics.line( last_x, last_y, x, y )
        last_v = v
    end
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

local pad = 16
local t = 0.0
local nval = 1.0
local Kval = 1.0
function love.update(_dt)
    t = t + _dt
    nval = sin_norm(t) * 14.0 + 1.0
end

function love.draw()
    love.graphics.clear()
    love.graphics.setColor(1,1,1,1)
    
    local region = frame_xy({
        pos     = { pad, pad },
        size    = { 500, 300 },
        x_range = { 0.0, 3.0 },
        y_range = { 0.0, 1.0 },
        grid    = {  10,  10 },
        subgrid = {   6,   3 },
        padding = 16,
        params  = {
            ["n"] = nval,
            ["K"] = Kval
        }
    })
    
    love.graphics.setColor(0.5,0.9,0.5)
    plot_func_line({
        func       = hill,
        params     = { Kval, nval },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = { 0.0, 4.0 },
        resolution = 512
    })

    love.graphics.setColor(0.9,0.5,0.5)
    plot_func_line({
        func       = hill2,
        params     = { Kval, nval },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = { 0.0, 4.0 },
        resolution = 512
    })
    
    love.graphics.setColor(0.5,0.5,0.9)
    plot_func_line({
        func       = hill_mult,
        params     = { Kval, nval, 2.0, nval },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = { 0.0, 4.0 },
        resolution = 512
    })
    
    love.graphics.setColor(1,1,1)
    
    local len = 200
    mv:ruler({
        pos_a=vec2(len+64, len+64),
        pos_b=vec2(len+64 + math.cos(t) * len, len+64 + math.sin(t) * len), 
        num_marks = 10, 
        num_submarks = 1, 
        mark_length = 7, 
        submark_length = 4,
        text_format = "%.2f", 
        text_range = {0.0, 1.0}
    })

    local ww = region.size[1] + pad*4
    local wh = region.size[2] + pad*2
    local window_width, window_height = love.window.getMode()
    local resize = window_width ~= ww or window_height ~= wh
    if resize then 
        love.window.setMode(ww, wh)
    end
end