local lib = {}

require "lua.math"

function lib:line(_a,_b)
    love.graphics.line(_a.X, _a.Y, _b.X, _b.Y)
end


function lib:text_centre( _text, _pos_x, _pos_y)
    local font = love.graphics.getFont()
    local pos_x = math.floor(_pos_x - font:getWidth (_text) / 2)
    local pos_y = math.floor(_pos_y - font:getHeight(_text) / 2)
    love.graphics.print(_text, pos_x, pos_y)
end

function lib:text_top( _text, _pos_x, _pos_y )
    local font = love.graphics.getFont()
    local pos_x = math.floor(_pos_x - font:getWidth (_text) / 2)
    local pos_y = math.floor(_pos_y)
    love.graphics.print(_text, pos_x, pos_y)
end

function lib:text_right( _text, _pos_x, _pos_y )
    local font = love.graphics.getFont()
    local pos_x = math.floor(_pos_x - font:getWidth (_text))
    local pos_y = math.floor(_pos_y - font:getHeight(_text) / 2)
    love.graphics.print(_text, pos_x, pos_y)
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
end


return lib
