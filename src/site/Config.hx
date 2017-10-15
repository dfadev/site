package site;

import ithril.Attributes;
import ithril.Ithril;
import ithril.M.*;
import util.From;

// Application configuration
class Config {
	// page attributes are a mangled config object
	static inline public function pageAttributes(href:String, state:Dynamic)
	{
#if !js
		var pageAttributes = new util.Cloner().merge(state, Reflect.field(state.pages, href));
		pageAttributes.href = href;
#else
		var pageAttributes = untyped __js__("Object.assign({0}, {1}, {2})", state, untyped __js__('{0}[href]', state.pages), { href: href });
#end
		return pageAttributes;
	}

#if !browser
	static public inline function defaults(config) {
		return new util.Cloner().merge(config, {
			pages: { },

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
				lang: "en",					// Default html lang
				javascript: true,			// Include javascript
				css: true,					// Include css
				options: { 
					dotFiles: "ignore",
					etag: false,
					extensions: false,
					index: [ "index.html", "index.htm" ],
					lastModified: true,
					maxAge: "24h",
					redirect: true
				},

				meta: ([
					   { charset: "utf-8" },
					   { name: "viewport", content: "width=device-width, initial-scale=1.0, shrink-to-fit=no" }
				]:Array<Dynamic>),

				link: ([]:Array<Dynamic>),

				// optionally embed javascript and css directly in page
				include: From.json('obj/build-config.json')
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

#end
		});
	}
#end
}
