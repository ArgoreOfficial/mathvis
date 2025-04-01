local lib = {}

require "mv_math"

local debug_canvas = love.graphics.newCanvas(100,100)
local g_scope_padding = 0

local function get_bounds(_v1,_v2,...)
    local min_x = math.min( _v1.X, _v2.X )
    local min_y = math.min( _v1.Y, _v2.Y )
    local max_x = math.max( _v1.X, _v2.X )
    local max_y = math.max( _v1.Y, _v2.Y )

    local v_arg = {...}
    for _,v in ipairs(v_arg) do
        min_x = math.min( min_x, v.X )
        min_y = math.min( min_y, v.Y )
        max_x = math.max( max_x, v.X )
        max_y = math.max( max_y, v.Y )
    end
    
    return {
        min_x, min_y,
        max_x - min_x, max_y - min_y
    }
end

local function scope(_parent, _left,_right,_top,_bottom)
    return {
        Left   = _left,
        Right  = _right,
        Top    = _top,
        Bottom = _bottom,
        Parent = _parent,
        Scopes = {}
    }
end

local p_scopetree = nil 
local p_scope = nil
local g_depth = 0
local g_maxdepth = 0

local function resize_scopes(_scope)
    if _scope == nil or _scope.Parent == nil then return end -- root

    _scope.Parent.Left   = math.min(_scope.Parent.Left,   _scope.Left)
    _scope.Parent.Top    = math.min(_scope.Parent.Top,    _scope.Top)
    _scope.Parent.Right  = math.max(_scope.Parent.Right,  _scope.Right)
    _scope.Parent.Bottom = math.max(_scope.Parent.Bottom, _scope.Bottom)
    
    resize_scopes(_scope.Parent)
end

local function push_scope(_left,_right,_top,_bottom)
    if not p_scope then return end

    local new_scope = scope(p_scope, _left, _right, _top, _bottom)
    table.insert(p_scope.Scopes, new_scope)
    p_scope = new_scope

    g_depth = g_depth + 1
    if g_depth > g_maxdepth then 
        g_maxdepth = g_depth 
    end

    resize_scopes(p_scope)
end

-- because pos + size is annoying when we're dealing with Left->Right and Top->Bottom
function lib:rectangle(_mode, _left, _top, _right, _bottom)
    _left   = math.floor(_left)
    _top    = math.floor(_top)
    _right  = math.floor(_right)
    _bottom = math.floor(_bottom)

    local size_y = math.floor(_bottom - _top)
    local size_x = math.floor(_right - _left)

    if _mode == "fill" then
        love.graphics.rectangle(_mode,_left, _top, size_x + 1, size_y)
    elseif _mode == "line" then
        love.graphics.rectangle(_mode, _left + 1, _top, size_x, size_y)
    end
end

function lib:begin_scope(_x,_y)
    p_scopetree = scope(nil, _x, _x, _y, _y)
    p_scope = p_scopetree
end

function lib:pop_scope()
    if p_scope == nil or p_scope.Parent == nil then 
        return { 
            Left   = 0, PaddedLeft   = 0, 
            Right  = 0, PaddedRight  = 0, 
            Top    = 0, PaddedTop    = 0, 
            Bottom = 0, PaddedBottom = 0 
        }
    end

    local current_scope = p_scope
    p_scope = p_scope.Parent
    g_depth = g_depth - 1

    return {
        Left   = current_scope.Left,   PaddedLeft   = current_scope.Left   - g_scope_padding,
        Right  = current_scope.Right,  PaddedRight  = current_scope.Right  + g_scope_padding,
        Top    = current_scope.Top,    PaddedTop    = current_scope.Top    - g_scope_padding,
        Bottom = current_scope.Bottom, PaddedBottom = current_scope.Bottom + g_scope_padding
    }
end

function lib:draw_scope(_x,_y,_w,_h)
    local right  = _x + _w
    local bottom = _y + _h
    push_scope(_x, right, _y, bottom)
end

function lib:on_resize(_w,_h)
    debug_canvas = love.graphics.newCanvas(_w,_h)
end

local function debug_draw_scope_box(_mode,_left,_right,_top,_bottom)
    lib:rectangle(_mode, _left, _top, _right, _bottom)
end

local function debug_draw_scope(_scope, _depth, _maxdepth)
    if _scope == nil then return end

    -- debug draw
    local depth_v = (_depth+1)/(_maxdepth+1)
    
    love.graphics.setColor(0.85,0,0.5,depth_v)
    debug_draw_scope_box("fill", _scope.Left, _scope.Right, _scope.Top, _scope.Bottom)
    --love.graphics.setColor(0,0,0,1)
    --debug_draw_scope_box("line", _scope.Left, _scope.Right, _scope.Top, _scope.Bottom)
    love.graphics.setColor(1,1,1,1)
    
    for i, v in ipairs(_scope.Scopes) do
        debug_draw_scope(v, _depth+1, _maxdepth)
    end
end

function lib:display_scopes(_tree)
    local mode, alphamode = love.graphics.getBlendMode( )
    local r, g, b, a = love.graphics.getColor()
    local canvas = love.graphics.getCanvas()

    -- draw
    love.graphics.setCanvas(debug_canvas)
    love.graphics.clear(0,0,0,0)
    debug_draw_scope(_tree.Scope, 0, _tree.MaxDepth)
    
    -- display
    love.graphics.setCanvas(canvas)
    love.graphics.setBlendMode("add","premultiplied")
    love.graphics.draw(debug_canvas)
    
    -- reset state
    love.graphics.setBlendMode(mode,alphamode)
    love.graphics.setColor(r,g,b,a)
    love.graphics.setCanvas(canvas)
end


function lib:end_scope()
    local tree = {
        Scope = p_scopetree,
        MaxDepth = g_maxdepth
    }

    p_scopetree = nil
    p_scope     = nil
    g_maxdepth  = 0
    g_depth     = 0

    return tree
end

function lib:draw_bound_scope(_v1,_v2,...)
    lib:draw_scope(unpack(get_bounds(_v1,_v2,...)))
end

function lib:line(_a,_b)
    lib:draw_bound_scope(_a,_b)
    love.graphics.line(_a.X+1, _a.Y, _b.X+1, _b.Y)
    lib:pop_scope()
end

function lib:text_centre( _text, _pos_x, _pos_y)
    local font = love.graphics.getFont()
    local width  = font:getWidth (_text)
    local height = font:getHeight(_text)
    local pos_x = math.floor(_pos_x - width / 2)
    local pos_y = math.floor(_pos_y - height / 2)

    lib:draw_scope(pos_x, pos_y, width, height)
    love.graphics.print(_text, pos_x, pos_y)
    lib:pop_scope()
end

function lib:text_top( _text, _pos_x, _pos_y )
    local font = love.graphics.getFont()
    local width  = font:getWidth (_text)
    local height = font:getHeight(_text)
    local pos_x = math.floor(_pos_x - width / 2)
    local pos_y = math.floor(_pos_y)

    lib:draw_scope(pos_x, pos_y, width, height)
    love.graphics.print(_text, pos_x, pos_y)
    lib:pop_scope()
end

function lib:text_right( _text, _pos_x, _pos_y )
    local font = love.graphics.getFont()
    local width  = font:getWidth (_text)
    local height = font:getHeight(_text)
    local pos_x = math.floor(_pos_x - width)
    local pos_y = math.floor(_pos_y - height / 2)

    lib:draw_scope(pos_x, pos_y, width, height)
    love.graphics.print(_text, pos_x, pos_y)
    lib:pop_scope()
end

function lib:ruler(_info)

	local pos_a          = _info.pos_a
	local pos_b          = _info.pos_b
	local num_marks      = _info.num_marks or 5
	local num_submarks   = _info.num_submarks or 2
	local mark_length    = _info.mark_length or 8
	local submark_length = _info.submark_length or 5
	local text_format    = _info.text_format
	local text_range     = _info.text_range
	local flip           = _info.flip or false

    num_marks    = num_marks - 1
    num_submarks = num_submarks - 1

    lib:line(pos_a,pos_b)
    
    local dx = pos_b.X - pos_a.X
    local dy = pos_b.Y - pos_a.Y
    
    local norm = nil
	if flip then norm = vec2_normalize(vec2(-dy,  dx))
	else         norm = vec2_normalize(vec2( dy, -dx)) end
	
    local mark_dir    = norm * mark_length
    local submark_dir = norm * submark_length

    lib:draw_bound_scope(
        pos_a, 
        pos_a+mark_dir, 
        pos_b,
        pos_b+mark_dir)
    
    for mark=0, num_marks do
        local mark_pos = lerp(pos_a, pos_b, mark/num_marks)
        lib:line(mark_pos, mark_pos + mark_dir)

		if text_format then
            local str = string.format(text_format, lerp(text_range[1], text_range[2], mark/num_marks))
			local strw = love.graphics.getFont():getWidth(str)  * 0.5
			local strh = love.graphics.getFont():getHeight(str) * 0.5
			local strpos = vec2(
				mark_pos.X - norm.X * strw,
				mark_pos.Y - norm.Y * strh
			)
			
			lib:text_centre(str, strpos.X, strpos.Y)
		end

        if mark < num_marks then
            local next_mark = lerp(pos_a, pos_b, (mark+1)/num_marks)

            for submark=0, num_submarks do
                local v = ((submark+1)/(num_submarks+2))
                local submark_pos = lerp(mark_pos, next_mark, v)
        
                lib:line(submark_pos, submark_pos+submark_dir)
            end
        end
    end

    return lib:pop_scope()
end

function lib:plot_func_line( _info )
    local func       = _info.func
    local params     = _info.params     or { }
    local pos        = _info.pos        or vec2(0,0)
    local size       = _info.size       or vec2(300, 100)
    local resolution = _info.resolution or size.Y
    local x_range    = _info.x_range    or { 0.0, 1.0 }
    
    local x_range_min,x_range_max = x_range[1] or 0.0, x_range[2] or 1.0
    local pixel_size = size - 1
    
    local function x_of(_v) return lerp(pos.X, pos.X + pixel_size.X, _v) end
    local function y_of(_v) return pos.Y + pixel_size.Y - (_v * pixel_size.Y) end

    lib:draw_bound_scope( pos, pos + pixel_size)

    local real_t = lerp(x_range_min, x_range_max, 0)
    local last_v = func(real_t, unpack(params))
    for i=1, resolution do
        local t = i / resolution
        local last_t = (i-1) / resolution
        real_t = lerp(x_range_min, x_range_max, t)
        local v = func(real_t, unpack(params))
        
        local x = x_of(t)
        local y = y_of(v)
        local last_x = x_of(last_t)
        local last_y = y_of(last_v)

        love.graphics.line( last_x, last_y, x, y )
        last_v = v
    end

    lib:pop_scope()
end

function lib:frame_xy( _info )
    local pos     = _info.pos     or vec2( 16,   16 )
    local size    = _info.size    or vec2( 256, 256 )
    local x_range = _info.x_range or { 0.0, 3.0 }
    local y_range = _info.y_range or { 0.0, 1.0 }
    local padding = _info.padding or 0
    local params  = _info.params  or { }
    local grid    = _info.grid    or vec2(6, 6)
    local subgrid = _info.subgrid or vec2(6, 6)

    local text_width  = love.graphics.getFont():getWidth ("0.00")
    local text_height = love.graphics.getFont():getHeight("0.00")

    local tl = pos + vec2(text_width, 0) -- shifted due to left ruler numbers. TODO: precompute regions with scopes
    local br = vec2(tl.X, tl.Y) + size + padding * 2
    
    lib:draw_bound_scope(tl, br)
    
    lib:draw_bound_scope(tl, br)
    lib:rectangle("line", tl.X, tl.Y, br.X, br.Y)
    local draw_area = lib:pop_scope()

    local bottom_ruler = lib:ruler({
        pos_a=vec2(draw_area.Left  + padding,draw_area.Bottom),
        pos_b=vec2(draw_area.Right - padding,draw_area.Bottom), 
        num_marks = grid.X, 
        num_submarks = subgrid.X, 
        mark_length = 8, 
        submark_length = 5,
        text_format = "%.2f", 
        text_range = x_range,
        flip = false
    })

    lib:ruler({
        pos_a=vec2(draw_area.Left, draw_area.Top + padding + size.Y),
        pos_b=vec2(draw_area.Left, draw_area.Top + padding ), 
        num_marks = grid.Y, 
        num_submarks = subgrid.Y, 
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
        
        lib:draw_scope(text_x, text_y, text_width, text_height)
        text_y = lib:pop_scope().PaddedBottom
    end

    local scope_reg = lib:pop_scope()

    local regions = {
        position = vec2( 
            scope_reg.Left, 
            scope_reg.Top 
        ),
        
        size = vec2( 
            scope_reg.Right  - scope_reg.Left, 
            scope_reg.Bottom - scope_reg.Top 
        ),
        
        plot_position = vec2( 
            draw_area.Left + padding, 
            draw_area.Top  + padding
        ),

        plot_size = size
    }

    return regions
end

function lib:plot(_mode, _info)
    if _mode == "line" then lib:plot_func_line(_info) end
end

return lib
