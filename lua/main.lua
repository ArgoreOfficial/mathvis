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
    local region = mv:frame_xy({
        pos     = vec2(pad, pad),
        size    = vec2(500, 300),
        x_range = { 0.0, 3.0 },
        y_range = { 0.0, 1.0 },
        grid    = vec2(11, 10),
        subgrid = vec2(6, 3),
        padding = pad,
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
    --mv:display_scopes( tree )
    
    local ww = region.position.X + region.size.X + pad + 1
    local wh = region.position.Y + region.size.Y + pad 
    local window_width, window_height = love.window.getMode()
    local resize = window_width ~= ww or window_height ~= wh
    if resize then 
        mv:on_resize(ww,wh)
        love.window.setMode(ww, wh)
    end
end