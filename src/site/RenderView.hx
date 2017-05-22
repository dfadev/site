package site;

class RenderView {
	static var res = { send: Sys.println, status: Sys.println };
	static var req = { path: '/' };
	static public function execute(config) {
		req.path = config.pathToRender;
		site.Views.render(req, res, function () throw 'missing path: ${req.path}');
	}
}
