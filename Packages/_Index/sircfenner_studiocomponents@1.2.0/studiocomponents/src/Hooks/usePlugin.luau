--[=[
	@class usePlugin
	
	A hook used to obtain a reference to the root [plugin](https://create.roblox.com/docs/reference/engine/classes/Plugin)
	instance associated with the current plugin. It requires a single [PluginProvider] to be present 
	higher up in the tree.

	```lua
	local function MyComponent()
		local plugin = usePlugin()
		...
	end
	```
]=]

local React = require(script.Parent.Parent.Parent:FindFirstChild('react'))

local PluginContext = require(script.Parent.Parent:FindFirstChild('Contexts'):FindFirstChild('PluginContext'))

local function usePlugin()
	local pluginContext = React.useContext(PluginContext)
	return pluginContext and pluginContext.plugin
end

return usePlugin
