Proxy = {}

local key = {}

local mt = {
	__index = function(t, k)
		if not t[key][k] and (t.BaseClass and type(t.BaseClass[k]) == "function") then
			return t.BaseClass[k]
		end

		return t[key][k]
	end,
	__newindex = function(t, k, v)
		if type(v) == "function" and (t.BaseClass and type(t.BaseClass[k]) == "function") then
			t[key][k] = function(...)
				t.BaseClass[k](...)
				return v(...)
			end

			return
		end

		t[key][k] = v
	end
}

function Proxy:Create(b)
	local proxy = { [key] = b and { BaseClass = b } or {} }
	return setmetatable(proxy, mt)
end

setmetatable(Proxy, {
	__call = Proxy.Create
})
