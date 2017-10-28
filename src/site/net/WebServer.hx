package site.net;

import js.npm.express.Middleware;
import js.npm.express.Middleware.MiddlewareNext;
import js.npm.express.Request;
import js.npm.express.Response;

class WebServer {
	static public var passportAuth:Middleware;

	static public function execute(config:Dynamic) {
		Evt.emit(Starting);

		var srv = new js.npm.Express();
		srv.set('etag', false);
		srv.set('x-powered-by', false);

		if (config.listen.compression) srv.use(new js.npm.express.Compression());
		if (config.listen.httpLogFormat != null) srv.use(new js.npm.express.Morgan(config.listen.httpLogFormat));
		srv.get('/favicon.ico', function (req, res:Dynamic) res.status(404).end());
		if (config.html.render)
			srv.get("*", config.html.renderFunction);
		srv.use('/', new js.npm.express.Static(config.html.path, config.html.options));

		var cookieParser = new js.npm.express.CookieParser();
		config.session.store = js.npm.SessionStore.createSessionStore(config.session.store);
		var sess = new js.npm.express.Session(cast config.session);
		var passportInit = js.npm.Passport.initialize();
		var passportSession = js.npm.Passport.session();

		srv.use(cookieParser).use(sess).use(passportInit).use(passportSession);

#if verbose
		srv.use(function (req:Request, res:Response, next:MiddlewareNext) {
			var user:Dynamic = untyped req.user;
			if (user) {
        Sys.println('user access: ${user.username}');
      }
			else Sys.println('anonymous access ${user}');
			next();
		});
#end

		for (key in Reflect.fields(config.auth)) {
			var provider = Reflect.field(config.auth, key);
			if (key == "options" || !provider.enable) continue;
      untyped __js__('{0}.use({1}, eval({2}), {3})', js.npm.Passport, key, provider.strategy, [provider, auth]);
			if (provider.callbackURL != null)
				srv.get(js.node.Url.parse(provider.callbackURL).path, js.npm.Passport.authenticate(key, config.auth.options));
		}

		WebServer.passportAuth = js.npm.Passport.authenticate('local', { failureRedirect: '/', successRedirect: '/' } );

		js.npm.Passport.serializeUser(serializeUser);
		js.npm.Passport.deserializeUser(deserializeUser);

		srv.get(config.auth.options.logoutURL, function(req:Dynamic, res) { req.logout(); res.redirect('/'); });

		srv.use(function(req, res:Dynamic) res.status(404).end());

		checkSocketAuth = untyped function (req, callback) cookieParser(req, {},
			function (err) (err != null) ? callback(err) : sess(req, {},
			function (err) (err != null) ? callback(err) : passportInit(req, {},
			function (err) (err != null) ? callback(err) : passportSession(req, {}, callback))));

		var http = cast js.node.Http.createServer().on('request', cast srv);
		http.listen(config.listen);
		
		if (config.listen.websockets) WebSocketServer.execute(http);
		if (config.appsrv != null && config.appsrv.length > 0) BackEnd.use(config.appsrv);

		Evt.emit(Started);

		return http;
	}

	static function auth(access, refresh, profile, cb) return cb(null, profile);
	static public dynamic function checkSocketAuth(req, callback) { }

  static public dynamic function serializeUser(user, cb) { }
  static public dynamic function deserializeUser(user, cb) { }
}
