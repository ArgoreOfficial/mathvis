
local concentration = 0.0

-- n = count
-- A = receptor
-- B = ligand molecules
-- K = reaction dissociation constant
-- [X] = concentration of chemical species X

local function hill( B, K, n )
    return (B^n) / (K^n + (B^n))
end

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

local function draw_text_centre( _text, _pos_x, _pos_y )
    local font = love.graphics.getFont()
    local w = font:getWidth(_text)
    local pos_x = _pos_x - w/2
    love.graphics.print( _text, pos_x, _pos_y )
    
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function draw_graph_scale( _info )

    local pos     = _info.pos     or { 16,   16 }
    local size    = _info.size    or { 256, 256 }
    local x_range = _info.x_range or { 0.0, 3.0 }
    local y_range = _info.y_range or { 0.0, 1.0 }
    local padding = _info.padding or 0.0
    local params  = _info.params  or { }

    local posx = pos[1]
    local posy = pos[2]
    local width  = size[1]
    local height = size[2]

    love.graphics.rectangle("line", posx, posy, width, height)

    local right  = posx + width
    local bottom = posy + height

    local num_segs = 6
    local seg = width / num_segs
    for i = 0, num_segs do
        local v = lerp( x_range[1], x_range[2], i / num_segs )
        local seg_x = posx + i * seg
        love.graphics.line( seg_x, bottom, seg_x, bottom - 5 )

        draw_text_centre(tostring(v), seg_x, posy + height )
    end
   
    local param_offset = 1
    for i, v in pairs(params) do
        local str = i .. "=" .. tostring(v)
        local text_height = love.graphics.getFont():getHeight( str )
        love.graphics.print(str, posx, posy + height + (param_offset * text_height))
        param_offset = param_offset + 1
    end
end

local graph = {}

local function sin_norm(_v) 
    return math.sin(_v) * 0.5 + 0.5
end

local function clamp(_v, _min, _max)
    return math.max( math.min( _v, _max ), _min )
end

function draw_func_graph(_func, _params, _pos_x, _pos_y, _width, _height, _resolution)
    local px_w = _width - 1
    local px_h = _height - 1
    
    local data = love.image.newImageData(_width,_height)
    
    local max = 3
    for i=0, _resolution do
        local xval = (i / _resolution) * max
        local v = _func( xval, unpack(_params) )

        local x = (xval / max) * _width
        local y = px_h - (v * _height)

        local in_x_range = (x >= 0 and x < _width)
        local in_y_range = (y >= 0 and y < _height)

        if in_x_range and in_y_range then
            data:setPixel(x,y,1,1,1,1)
        end
    end
    
    local image = love.graphics.newImage(data)
    love.graphics.draw(image, _pos_x, _pos_y)
end

local t = 0.0
local nval = 1.0
local Kval = 1.0
function love.update(_dt)
    t = t + _dt
    nval = sin_norm(t) * 19.0 + 1.0

    graph = {}
    for i=0, 3, 0.1 do
        graph[#graph+1] = hill(i, Kval, nval )
    end
end

function love.draw()
    love.graphics.clear()
    love.graphics.setColor(1,1,1,1)
    
    local xmax = 3
    local w = 128 * xmax

    local graph_scale_info = {
        pos  = {32,32},
        size = {w,256},
        x_range = {0.0, 3.0},
        y_range = {0.0, 1.0},
        padding = 0.0,
        params = {
            ["n"] = nval,
            ["K"] = Kval
        }
    }

    draw_func_graph( hill, {Kval, nval}, 32, 32, w, 256, 4096 )
    --draw_graph( graph, 32, 32, w, 256)
    draw_graph_scale( graph_scale_info )

end