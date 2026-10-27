local _, ns = ...

local ShortestPath = {}
ns.ShortestPath = ShortestPath

---@param owner string
---@param stops table[]
---@return boolean
function ShortestPath.Navigate(owner, stops)
	local api = ShortestPathForever and ShortestPathForever.API
	if type(api) ~= "table" or type(api.NavigateRoute) ~= "function" then
		return false
	end
	local ok, started = pcall(api.NavigateRoute, owner, stops)
	return ok and started == true
end

return ShortestPath
