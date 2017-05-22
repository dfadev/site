package site; 

import ithril.HTMLRenderer;
import ithril.M.*;

using Reflect;

// Execute and render views
class Views {
	static var routes:Dynamic = { };
	public static function setRoute(key:String, value:Dynamic) routes.setField(key, { render: value });
#if browser
	public static function execute(config) {
		routePrefix(config.route.prefix);
		route(js.Browser.document.body, "/", routes);
		if (config.ws.enable) site.WebSocketClient.execute(config.ws);
	}
#elseif (webserver || renderview)
	public static function render(request, response:Dynamic, next:Dynamic) {
		var route = routes.field(request.path);
		if (route == null || route.render == null) {
			if (next == null)
				response.status(500).end();
			else
				next();
		}
		else
			HTMLRenderer.render(route.render())
				.then(function(rslt) { response.send(rslt); },
					  function(err) { Sys.println('ERR: $err'); response.status(500).end(); });
	}
#end
}
