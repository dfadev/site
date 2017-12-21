import ithril.M.*;
import site.util.From;
import site.net.*;
import site.view.*;
import site.Evt;
import msg.*;

class Site {
	static public inline function run(msgType, handler)
#if browser Views #elseif webserver WebServer #elseif renderview RenderView #elseif appserver TcpServer #end
		.execute(Site.setup(msgType, handler));

#if !browser
		static function parseConfig(configFilename:String) {
			var data = haxe.Json.parse(sys.io.File.getContent(configFilename));
			var config = #if appserver data.appserver #else data.webserver #end;
			config.pages = data.pages;
			return config;
		}
#end

	static public function setup(msgType, msgHandler) {
#if browser
		var config:Dynamic = From.json("config.json", "browser");
		config.pages = From.json("config.json", "pages");
#else
		var config:Dynamic = { };
		var configFilename = "config.json";
		var outputPath = 'htdocs';

		// process arguments
		var args = Sys.args();
		var help = function help(msg) {
			Sys.println(msg);
			Sys.exit(0);
		};
		var argHandler = util.Args.generate([
			@doc("Configuration file")
			["-c", "--config"] => function(fname) configFilename = fname,

			#if renderview
			@doc("Output path")
			["-o", "--output"] => function(path:String) outputPath = path,
			#end

			_ => function(arg:String) help('Error: $arg\n')
		]);

		argHandler.parse(args);
		config = parseConfig(configFilename);
		config.outputPath = outputPath;
		From.removeMeta(config.pages);

		// merge in defaults with config (except browser, require explicit config values there)
		config = site.Config.defaults(config);

		#if webserver
		if (config.html.render) config.html.renderFunction = site.view.Views.render;
		#end

#end


#if (!appserver && (!browser || site_ithril))
		// setup routing
		#if !js
		var fields:Array<String> = Reflect.fields(config.pages);
		#else
		var fields:Array<String> = untyped __js__("Object.keys({0})", config.pages);
		#end
		for (href in fields) {
			Views.setRoute(href, function (vnode) {
				return m(HtmlBase, site.Config.pageAttributes(href, config));
			});
		}
#end

		// let Evt know about our message type and handler
#if (!browser || site_websocket)
		Evt.setup(msgType, msgHandler);
#end

		return config;
	}

#if browser
	static public function throttle(fn:Dynamic, threshhold:Int) { //, scope) {
	  var last:Int = 0,
		  deferTimer;
	  return function () {
		var context = untyped __js__('this'); //scope || this;

		var now = untyped __js__('+new Date'),
			args = untyped __js__('arguments');
		if (last != 0 && now < last + threshhold) {
		  // hold on to it
		  js.Browser.window.clearTimeout(deferTimer);
		  deferTimer = js.Browser.window.setTimeout(function () {
			last = now;
			fn.apply(context, args);
		  }, threshhold);
		} else {
		  last = now;
		  fn.apply(context, args);
		}
	  };
	}
#end

#if browser
	public static inline function send(msg) site.net.WebSocketClient.send(msg);
  public static inline function goto(path) site.view.Views.goto(path);
#end
#if webserver
  public static inline function setPassportParseUser(serialize, deserialize) {
    site.net.WebServer.serializeUser = serialize;
    site.net.WebServer.deserializeUser = deserialize;
  }
	public static inline function passportAuth(req, res, next) untyped site.net.WebServer.passportAuth(req, res, next);
	public static inline function backend(msg) site.net.BackEnd.send(0, msg);
	public static inline function send(clientId:Int, msg) site.net.WebSocketServer.send(clientId, msg);
	public static inline function sendb(id, bytes) site.net.WebSocketServer.sendb(id, bytes);

	public static inline function user(id) {
		var socket = site.net.WebSocketServer.sockets.get(id);
		if (socket == null) return null;

		var user:Dynamic = socket.req.user;
		return user;
	}

	public static inline function req(id) {
		var socket = site.net.WebSocketServer.sockets.get(id);
		if (socket == null) return null;

		return socket.req;
	}
#end
#if appserver
	public static inline function send(id, msg) site.net.TcpServer.send(id, msg);
	public static inline function work(func) site.net.TcpServer.srv.work(func);
#end
}
