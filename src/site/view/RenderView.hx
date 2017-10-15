package site.view;

using Reflect;

class RenderView {
	static public function execute(config) {
		Sys.println("Generating static html");
		for (href in Reflect.fields(config.pages)) {
			site.view.Views.render(
				{ path: href },
				{
					send: function(txt) {
						if (href == "/") href = "index.html";
						var filename = haxe.io.Path.join( [ config.outputPath, href ] );
						sys.io.File.saveContent(filename, txt);
					},
					status: function(s) {
					}
				}, function () throw 'missing path: ${href}');
		}
	}
}
