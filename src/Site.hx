import ithril.M.*;
import util.From;
import site.net.*;
import site.view.*;
import msg.*;

class Site {

	static var cfg = Site.setup("model.NetworkMessage", function (e) controller.Handler.handle(NetworkEvent(e)));

#if browser
	static public inline function run() Views.execute(cfg);
#elseif webserver
	static public inline function run() WebServer.execute(cfg);
#elseif renderview
	static public inline function run() RenderView.execute(cfg);
#elseif appserver
	static public inline function run() TcpServer.execute(cfg);
#end

	static public function setup(msgType, msgHandler) {
#if browser
		var config:Dynamic = util.From.json("config/browser-config.json");
		config.pages = util.From.json("config/pages-config.json");
#else
		var config:Dynamic = { };

		// process arguments
		var args = Sys.args();
		var help = function help(msg) {
			Sys.println(msg);
			Sys.exit(0);
		};
		var argHandler = util.Args.generate([
			@doc("Pages configuration file")
			["-d", "--pages"] => function(pagesConfigFilename:String) config.pages = haxe.Json.parse(sys.io.File.getContent(pagesConfigFilename)),

			@doc("Configuration file")
			["-c", "--config"] => function(configFilename:String) config = haxe.Json.parse(sys.io.File.getContent(configFilename)),
#if renderview
			@doc("Output path")
			["-o", "--output"] => function(outputPath:String) config.outputPath = outputPath,
#end

			_ => function(arg:String) help('Error: $arg\n')
		]);

		if (args.length < 2) help('Missing arguments\n' + argHandler.getDoc()); else argHandler.parse(args);

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
			var view = m(HtmlBase, site.Config.pageAttributes(href, config));
			Views.setRoute(href, function (vnode) return view);
		}
#end

		// let DataMessage know about our message type and handler
#if (!browser || site_websocket)
		DataMessage.use(msgType, msgHandler);
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

}
