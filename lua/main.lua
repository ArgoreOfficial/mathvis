_G._DEBUG = false

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
    local right  = left + width  + padding * 2
    local bottom = top  + height + padding * 2

    mv:draw_bound_scope(vec2(left,top), vec2(right, bottom))
    
    mv:draw_bound_scope(vec2(left,top), vec2(right, bottom))
    mv:rectangle("line", left, top, right, bottom)
    local draw_area = mv:pop_scope()

    local bottom_ruler = mv:ruler({
        pos_a=vec2(draw_area.Left  + padding,draw_area.Bottom),
        pos_b=vec2(draw_area.Right - padding,draw_area.Bottom), 
        num_marks = segs_x, 
        num_submarks = sub_segs_x, 
        mark_length = 8, 
        submark_length = 5,
        text_format = "%.2f", 
        text_range = x_range,
        flip = false
    })

    mv:ruler({
        pos_a=vec2(draw_area.Left, draw_area.Top + padding + height),
        pos_b=vec2(draw_area.Left, draw_area.Top + padding ), 
        num_marks = segs_y, 
        num_submarks = sub_segs_y, 
        mark_length = 8, 
        submark_length = 5,
        text_format = "%.2f", 
        text_range = y_range,
        flip = true
    })
    
    local text_y = bottom_ruler.PaddedBottom
    for i, v in pairs(params) do
        local str = i .. "=" .. tostring(v)
        local text_height = love.graphics.getFont():getHeight(str)
        local text_width  = love.graphics.getFont():getWidth(str)
        local text_x = draw_area.Left

        love.graphics.print(str, text_x, text_y)
        
        mv:draw_scope(text_x, text_y, text_width, text_height)
        text_y = mv:pop_scope().PaddedBottom
    end

    local scope_reg = mv:pop_scope()

    local regions = {
        position = { scope_reg.Left, scope_reg.Right },
        size = { scope_reg.Right - scope_reg.Left, scope_reg.Bottom - scope_reg.Top },
        plot_position = {draw_area.Left + padding, draw_area.Top + padding},
        plot_size     = {width, height}
    }

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

local function plot_func( _info )
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
    
    mv:begin_scope(pad+16,pad+16)
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
    mv:plot("line", {
        func       = hill,
        params     = { Kval, nval },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = { 0.0, 4.0 },
        resolution = 512
    })

    love.graphics.setColor(0.9,0.5,0.5)
    mv:plot("line", {
        func       = hill2,
        params     = { Kval, nval },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = { 0.0, 4.0 },
        resolution = 512
    })
    
    love.graphics.setColor(0.5,0.5,0.9)
    mv:plot("line", {
        func       = hill_mult,
        params     = { Kval, nval, 2.0, nval },
        pos        = region.plot_position,
        size       = region.plot_size,
        x_range    = { 0.0, 4.0 },
        resolution = 512
    })
    local tree = mv:end_scope()
    mv:display_scopes( tree )
    
    local ww = region.size[1] + pad*2
    local wh = region.size[2] + pad*2
    local window_width, window_height = love.window.getMode()
    local resize = window_width ~= ww or window_height ~= wh
    if resize then 
        mv:on_resize(ww,wh)
        love.window.setMode(ww, wh)
    end
end