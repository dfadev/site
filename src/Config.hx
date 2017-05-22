import site.*;
import ithril.Attributes;
import ithril.Ithril;
import ithril.M.*;
import util.From;

using Reflect;
using Lambda;

// Application configuration
class Config {
	static public function setup() {
#if browser
		var config:Dynamic = util.From.json("config/browser-config.json");
#else
		var config:Dynamic = { };

		// process arguments
		var args = Sys.args();
		var help = function help(msg) {
			Sys.println(msg);
			Sys.exit(0);
		};
		var argHandler = util.Args.generate([

			@doc("Configuration file")
			["-c", "--config"] => function(configFilename:String) config = haxe.Json.parse(sys.io.File.getContent(configFilename)),
#if renderview
			@doc("Path to render")
			["-p", "--path"] => function(path:String) config.pathToRender = path,
#end

			_ => function(arg:String) help('Error: $arg\n')
		]);

		if (args.length < 2) help('Missing arguments\n' + argHandler.getDoc()); else argHandler.parse(args);
#end
		// merge in defaults with config
		config = defaults(config);

#if !appserver
		// setup routing
		for (href in config.pages.fields()) {
			var view = m(HtmlBase, pageAttributes(href, config));
			Views.setRoute(href, function (vnode) return view);
		}
#end

#if !renderview
		// let DataMessage know about our message type and handler
		DataMessage.use(Message.NetworkMessage, function (msg) Message.handler(Event(msg)));
#end

		return config;
	}

	// page attributes are a mangled config object
	static inline function pageAttributes(href:String, state:Dynamic)
		return Attributes.combine(Attributes.combine(state.pages.field(href), state), { href: href });

	static inline function defaults(config) {
		return new util.Cloner().merge(config, {
			pages: {
				"/": {
					component: "www.HomePage",
					title: "Home",
				}
			},

#if appserver
			listen: {
				port: "5200", 				// Port to listen on
				host: "localhost", 			// IP address to bind to
			}
#elseif browser
			ws: {
				enable: true,
				url: "ws://localhost:4200",	// WS URL browser connects to",
				reconnect: {
					minimumDelay: "1000",	// Minimum delay before reconnecting",
					maximumDelay: "10000",	// Maximum delay before reconnecting",
					step: "500",			// Step this much per try",
				}
			},

			route: {
				prefix: ""					// Route prefix to use
			}
#elseif (webserver || renderview)
			html: {
				path: "htdocs",  			// Path to static HTML files
				render: true,				// Should rendered HTML be served
				charset: "utf-8",			// Default charset meta
				javascript: true,			// Include javascript
				css: true,					// Include css
			},

			listen: {
				port: "4200", 				// Port to listen on
				host: "localhost", 			// IP address to bind to
				httpLogFormat: "dev", 		// Morgan HTTP format string
				compression: true, 			// Enable gzip compression
				backlog: 511, 				// Maximum queued connections
				websockets: true,			// Enable websockets
			},

			appsrv: [
			{
				host: "localhost",
				port: 5200
			}
			],

			session: {
				name: "",					// Session name
				resave: false,				// Resave every time
				saveUninitialized: true,	// Save uninitialized sessions
				secret: "123",				// Secret hashing
				store: {					// SessionStore configuration
				}
			},

			auth: {
				options: {
					failureRedirect: "/",	// Redirect here on bad auth
					successRedirect: "/",	// Redirect here on successful auth
					failureFlash: "",		// Flash this message on bad auth
					successFlash: "",		// Flash this message on successful auth
					scope: [ ],				// Auth scope
					display: "",			// Auth description
					session: true,			// Use session cookie
					logoutURL: "/logout",	// URL to logout user
				},

				github: {					// GitHub auth config
					enable: false,
					clientID: "",
					clientSecret: "",
					callbackURL: "http://localhost:4200/github",
					strategy: "passport-github"
				},

				facebook: {					// Facebook auth config
					enable: false,
					clientID: "",
					clientSecret: "",
					callbackURL: "http://localhost:4200/facebook",
					strategy: "passport-facebook"
				},

				google: {					// Google auth config
					enable: false,
					clientID: "",
					clientSecret: "",
					callbackURL: "http://localhost:4200/google",
					strategy: "passport-google-oauth20"
				},

				twitter: {					// Twitter auth config
					enable: false,
					consumerKey: "",
					consumerSecret: "",
					callbackURL: "http://localhost:4200/twitter",
					strategy: "passport-twitter"
				}
			},

			// embed javascript directly in page
			script: !config.html.javascript ? [] :
				([
	#if compress
				#if uglifyjs
					{ content: From.command('uglifyjs', [ '--compress', '--mangle', '--',
						'node_modules/mithril/mithril.min.js',
						'node_modules/mithril/stream/stream.js',
						'obj/browser.js', ]),
					  type: "text/javascript" },
				#else
					{ content: From.file('node_modules/mithril/mithril.min.js'),
					  attributes: { type: "text/javascript" } },
					{ content: From.file('node_modules/mithril/stream/stream.js'),
					  attributes: { type: "text/javascript" } },
					{ content: From.command('closure-compiler', [ '-O', 'SIMPLE', 'obj/browser.js', ]),
					  attributes: { type: "text/javascript" } },
				#end
	#else
					{ content: From.file('node_modules/mithril/mithril.js'),
					  attributes: { type: "text/javascript" } },
					{ content: From.file('node_modules/mithril/stream/stream.js'),
					  attributes: { type: "text/javascript" } },
					{ content: From.file('obj/browser.js'),
					  attributes: { type: "text/javascript" } },
					// non-embedded script:
					//{ type: "text/javascript", src: "browser.js" },
	#end
				]:Dynamic),

			// embed css directly in page
			css: !config.html.css ? [] :
				[
	#if compress
					{ content: From.command('sass', [ 'include/css/style.scss', '--style', 'compressed', ]),
					  attributes: { type: "text/css" } },
	#else
					{ content: From.command('sass', [ 'include/css/style.scss', '--style', 'compact', ]),
					  attributes: { type: "text/css" } },
	#end
				],

			meta: ([
					{ charset: config.html.charset },
					{ name: "viewport", content: "width=device-width, initial-scale=1.0" }
			]:Array<Dynamic>),

			link: ([
				{ rel: "icon", type: "image/x-icon", href: "data:image/x-icon;base64,AAABAAEAEBAQAAEABAAoAQAAFgAAACgAAAAQAAAAIAAAAAEABAAAAAAAgAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAA/7VrAP8AJgD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAEQARAAEAEQERABEQEQARERERERERABEREREREREAEREREREREQARERERERERABERMxERMxEAERMyIRMyIQABEzIhEzIgAAETMzETMzAAAREzEREzEAAAEREREREAAAABEREREAAAAAABERAAAAAAAAAAAAAAD//wAAuZ0AAJGJAACAAQAAgAEAAIABAACAAQAAgAEAAIABAADAAwAAwAMAAMADAADgBwAA8A8AAPw/AAD//wAA" }
			]),
#end
		});
	}
}
