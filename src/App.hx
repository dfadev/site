import site.*;
// Main application entry point
class App {
	static var config:Dynamic = Config.setup();
#if browser
	static function main() Views.execute(config);
#elseif webserver
	static function main() WebServer.execute(config);
#elseif renderview
	static function main() RenderView.execute(config);
#elseif appserver
	static function main() TcpServer.execute(config);
#end
}
