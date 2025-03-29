require "lua.vec"

function _G.lerp(_a, _b, _t)
	return _a + (_b - _a) * _t
end

function _G.vec2_len(_vec2)
    return math.sqrt( _vec2.X^2 + _vec2.Y^2 )
end

function _G.vec2_normalize(_vec2)
    local len = vec2_len(_vec2)
    return vec2(
        _vec2.X / len,
        _vec2.Y / len
    )
end
