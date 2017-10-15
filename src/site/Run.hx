package site;

import haxe.io.Path;

class Run {
	public static function main() {
		var args = Sys.args();
		var sitelib = args.pop();
		var filename = Path.join([ sitelib, 'obj', 'site' ]);
		if (!sys.FileSystem.exists(filename)) {
			Sys.command('cd ' + sitelib + ' && haxe build.hxml');
		}
		Sys.command(filename, args);
	}
}
