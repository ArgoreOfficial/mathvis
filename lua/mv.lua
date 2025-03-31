local lib = {}

require "mv_math"

local debug_canvas = love.graphics.newCanvas(100,100)

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

local debug_pad = 2
local p_scopetree = nil 
local p_scope = nil
local g_depth = 0
local g_maxdepth = 0

local function resize_scopes(_scope)
    if _scope == nil or _scope.Parent == nil then return end -- root

    _scope.Parent.Left = math.min(_scope.Parent.Left, _scope.Left)
    _scope.Parent.Top = math.min(_scope.Parent.Top, _scope.Top)
    _scope.Parent.Right = math.max(_scope.Parent.Right, _scope.Right)
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

function lib:begin_scope(_x,_y)
    p_scopetree = scope(nil, _x, _x, _y, _y)
    p_scope = p_scopetree
end

function lib:pop_scope()
    if p_scope == nil or p_scope.Parent == nil then 
        return 
    end

    local current_scope = p_scope
    p_scope = p_scope.Parent
    g_depth = g_depth - 1

    return {
        Left   = current_scope.Left,
        Right  = current_scope.Right,
        Top    = current_scope.Top,
        Bottom = current_scope.Bottom
    }
end

function lib:draw_scope(_x,_y,_w,_h)
    local right  = _x + _w
    local bottom = _y + _h
    push_scope(_x-1,right+1,_y-1,bottom+1)
end

function lib:on_resize(_w,_h)
    debug_canvas = love.graphics.newCanvas(_w,_h)
end

local function debug_draw_scope_box(_mode,_left,_right,_top,_bottom)
    local w = _right - _left
    local h = _bottom - _top
    love.graphics.rectangle(
        _mode,
        _left,-- - debug_pad - 1,
        _top,-- - debug_pad,
        w, -- + debug_pad * 2 + 1,
        h -- + debug_pad * 2 + 1
    )
end

local function debug_draw_scope(_scope, _depth, _y, _maxdepth)
    if _scope == nil then return end

    -- debug draw
    love.graphics.setCanvas(debug_canvas)
    local depth_v = (_depth+1)/(_maxdepth+1)
    love.graphics.setColor(0.85,0,0.5,depth_v)
    debug_draw_scope_box("fill",_scope.Left, _scope.Right, _scope.Top, _scope.Bottom)
    --love.graphics.setColor(1,1,1,1)
    --debug_draw_scope_box("line",_scope.Left, _scope.Right, _scope.Top, _scope.Bottom)

    local y = _y
    for i, v in ipairs(_scope.Scopes) do
        y = y + 8
        y = debug_draw_scope(v, _depth+1, y, _maxdepth)
    end
    return y
end

function lib:display_scopes(_tree)
    local mode, alphamode = love.graphics.getBlendMode( )
    local r, g, b, a = love.graphics.getColor()
    local canvas = love.graphics.getCanvas()

    -- draw
    love.graphics.setCanvas(debug_canvas)
    love.graphics.clear(0,0,0,0)
    debug_draw_scope(_tree.Scope, 0, 0, _tree.MaxDepth)
    
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
    love.graphics.line(_a.X, _a.Y, _b.X, _b.Y)
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
			local strw = love.graphics.getFont():getWidth(str)  * 0.75
			local strh = love.graphics.getFont():getHeight(str) * 0.75
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

    lib:draw_bound_scope(
        vec2(pos_x,pos_y),
        vec2(pos_x,pos_y) + vec2(px_w, px_h))

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

    lib:pop_scope()
end

function lib:plot(_mode, _info)
    if _mode == "line" then lib:plot_func_line(_info) end
end

return lib
