local React = require(script.Parent.Parent.Parent:FindFirstChild('react'))

export type PluginContext = {
	plugin: Plugin,
	pushMouseIcon: (icon: string) -> string,
	popMouseIcon: (id: string) -> ()
}

return React.createContext(nil :: PluginContext?)
