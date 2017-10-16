package site.view; 

import ithril.HTMLRenderer;
import ithril.M.*;

using Reflect;

// Execute and render views
class Views {
	static var routes:Dynamic = { };
	public static function setRoute(key:String, value:Dynamic) routes.setField(key, { render: value });

#if browser
	public static function execute(config) {
		site.Evt.emit(Starting);
#if site_ithril
		routePrefix(config.route.prefix);
		var path = js.Browser.document.location.pathname;
		if (path == "/index.html") path = "/";
		route(js.Browser.document.body, path, routes);
#end
#if site_websocket
		if (config.ws.enable) site.net.WebSocketClient.execute(config.ws);
#end
		site.Evt.emit(Started);
	}

#elseif (webserver || renderview)
	public static function render(request:Dynamic, response:Dynamic, next:Dynamic) {
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
