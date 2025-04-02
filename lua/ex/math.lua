require "ex.vec"

local mathex = {}

function mathex.sin_norm(_v) 
    return math.sin(_v) * 0.5 + 0.5
end

function mathex.cos_norm(_v) 
    return math.cos(_v) * 0.5 + 0.5
end

function mathex.clamp(_v, _min, _max)
    return math.max( math.min( _v, _max ), _min )
end

function mathex.lerp(_a, _b, _t)
	return _a + (_b - _a) * _t
end

function mathex.vec2_len(_vec2)
    return math.sqrt( _vec2.X^2 + _vec2.Y^2 )
end

function mathex.vec2_normalize(_vec2)
    local len = mathex.vec2_len(_vec2)
    return vec2(
        _vec2.X / len,
        _vec2.Y / len
    )
end

if true then -- if supports_G_edit then
    _G.mathex = mathex
else
    return mathex
end