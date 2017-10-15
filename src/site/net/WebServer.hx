package site.net;

class WebServer {
	static public function execute(config:Dynamic) {
		DataMessage.emit(Starting);

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

		for (key in Reflect.fields(config.auth)) {
			var provider = Reflect.field(config.auth, key);
			if (key == "options" || !provider.enable) continue;
			js.npm.Passport.use(key, untyped Type.createInstance(untyped require(provider.strategy).Strategy, [provider, auth]));
			srv.get(js.node.Url.parse(provider.callbackURL).path, js.npm.Passport.authenticate(key, config.auth.options));
		}

		js.npm.Passport.serializeUser(function(user, cb) cb(null, user));
		js.npm.Passport.deserializeUser(function(user, cb) cb(null, user));

		srv.get(config.auth.options.logoutURL, function(req:Dynamic, res) { req.logout(); res.redirect('/'); });

		srv.use(function(req, res:Dynamic) res.status(404).end());

		checkSocketAuth = untyped function (req, callback) cookieParser(req, {},
			function (err) (err != null) ? callback(err) : sess(req, {},
			function (err) (err != null) ? callback(err) : passportInit(req, {},
			function (err) (err != null) ? callback(err) : passportSession(req, {}, callback))));

		var http = cast js.node.Http.createServer().on('request', cast srv);
		http.listen(config.listen);
		
		if (config.listen.websockets) WebSocketServer.execute(http);
		if (config.appsrv != null && config.appsrv.length > 0) TcpClient.use(config.appsrv);

		DataMessage.emit(Started);

		return http;
	}

	static function auth(access, refresh, profile, cb) return cb(null, profile);
	static public dynamic function checkSocketAuth(req, callback) { }
}
