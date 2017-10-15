package site;

import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import util.From;
import haxe.Json;
import haxe.ds.StringMap;

using Lambda;

class Make {
	public static function main() new Make();
	var args:Array<String>;
	var configFilename:String;
	var configOutputFilename:String;
	var config:Dynamic;
	var javascriptConfig:Array<Dynamic> = [ ];
	var cssConfig:Array<Dynamic> = [ ];
	var compress:Bool;
	var verbose:Bool;
	var cmd:String;
	var cwd:String;
	var siteLib:String;

	function new() {
		args = Sys.args();
		siteLib = From.getCommandOutputAsString("haxelib", ['path', 'site']).split("\n")[0];
		siteLib = siteLib.substring(0, siteLib.length - 4);

		cwd = Sys.getCwd();

		cmd = args[0];
		if (cmd == null || cmd == "help") {
			help();
		} else if (cmd == "npm") {
			installNodeModules();
		} else if (cmd == "install") {
			install();
		} else if (cmd == "init") {
			init();
		} else if (cmd == "pack") {
			pack();
		} else if (cmd == "hxml") {
			hxml();
		} else {
			readConfigFile();
			var script = Reflect.field(config.scripts, cmd);
			if (script != null) {
				if (verbose) Sys.println(script);
				Sys.command(script);
			} else Sys.println('unknown command: $cmd');
		}
	}

	function help() {
		Sys.println(' ---------------------------');
		Sys.println('| Site Help                 |');
		Sys.println(' ---------------------------\n');
		Sys.println('site install [?path]');
		Sys.println('   Install \'site\' convenience executable, default path is /usr/local/bin.  Should be run as root.\n');
		Sys.println('site init');
		Sys.println('   Copy site boiler plate to current directory and build it\n');
		Sys.println('site build');
		Sys.println('   Build site\n');
		Sys.println('site autobuild');
		Sys.println('   Build site, then wait for changes and build site again\n');
		Sys.println('site run');
		Sys.println('   Start webserver and appserver, restart on changes\n');
	}

	function deploy(src, dest) {
		if (!FileSystem.exists(dest)) {
			File.copy(src, dest);
		}
	}

	function readConfigFile() {
		configFilename = Path.join([cwd, "config.json"]);
		config = Json.parse(File.getContent(configFilename));
		var pages = config.pages;
		config = config.site;
		config.pages = pages;
		From.removeMeta(config);
		compress = config.browser.compress;
		verbose = config.verbose;
	}

	function installNodeModules() {
		if (FileSystem.exists("node_modules")) return;
		Sys.println('Running npm install');
		Sys.command("npm install");
	}

	function pack() {
		readConfigFile();
		configOutputFilename = Path.join([cwd, 'obj', 'build-config.json' ]);
		packageJavascript();
		packageCss();

		var result = haxe.Json.stringify({
			script: javascriptConfig,
			css: cssConfig
		});

		File.saveContent(configOutputFilename, result);
		if (verbose) Sys.println('created $configOutputFilename');
	}

	function install() {
		var filename = args.length == 1 ? Path.join([ '/', 'usr', 'local', 'bin', 'site' ])  : Path.join([args[1], 'site']);
		try {
			Sys.command('cp', [ '-p', Path.join([ siteLib, 'obj', 'site' ]), filename ]);
		} catch (err:Dynamic) {
			Sys.println('Failed to install $filename, are you root?');
			Sys.exit(-1);
		}
	}

	function init() {
		Sys.command('cp -ruv --backup=t ' + siteLib + 'template/* .');
	}

	function hxml() {
		readConfigFile();
		configOutputFilename = Path.join([cwd, 'obj', 'build-config.hxml' ]);
		Sys.println('Creating $configOutputFilename');

		var content = "";

		if (config.browser.mithril) content += '-D site_ithril\n';
		if (config.browser.websocket) content += '-D site_websocket\n';

		var options:Array<Dynamic> = config.options;
		for (option in options) {
			var key = Reflect.fields(option)[0];
			if (key == "__s" || key == null) content += '$option\n';
			else {
				var value = Reflect.field(option, key);
				content += '$key $value\n';
			}
		}

		var defines:Array<Dynamic> = config.defines;
		for (define in defines) {
			var key = Reflect.fields(define)[0];
			if (key == "__s" || key == null) content += '-D $define\n';
			else {
				var value = Reflect.field(define, key);
				content += '-D $key=$value\n';
			}
		}
		File.saveContent(configOutputFilename, content);

		// include components
		var pagesOutputFilename = Path.join([cwd, 'obj', 'pages-config.hxml' ]);
		content = "";
		var keys = Reflect.fields(config.pages);
		var components = new StringMap();
		for (key in keys) components.set(Reflect.field(config.pages, key).component, "");
		for (value in components.keys()) content += '$value\n';
		File.saveContent(pagesOutputFilename, content);
	}

	function packageJavascript() {
		Sys.println('Packing javascript');

		var scripts:Array<Entry> = config.javascript;
		var combined:String = "";
		for (script in scripts) {
			FileSystem.createDirectory(script.dest);
			var src = script.src[0];
			var src_href = script.href[0];
			var src_out = Path.join([script.dest, Path.withoutDirectory(src_href)]); 

			var src_min = script.src[1];
			var src_min_href = script.href[1];
			var src_min_out = Path.join([script.dest, Path.withoutDirectory(src_min_href)]);

			// minify js if necessary
			if (script.minifier != null) {
				var minifier = Reflect.field(config.minifiers, script.minifier);
				var args:Array<String> = minifier.args.concat([src]);
				if (verbose) Sys.println('${minifier.proc} ${args.join(' ')} > $src_min_out');
				var minifiedOutput = From.getCommandOutputAsString(minifier.proc, args);
				File.saveContent(src_min_out, minifiedOutput);
			} else {
				if (verbose) Sys.println('cp $src_min $src_min_out');
				File.copy(src_min, src_min_out);
			}

			// copy unminified js
			if (verbose) Sys.println('cp $src $src_out');
			File.copy(src, src_out);

			// create javascriptConfig
			var filename = compress ? src_min_out : src_out;
			var href = compress ? src_min_href : src_href;

			if (script.method == 'embed') {
				if (verbose) Sys.println('embedding');
				var content = File.getContent(filename);
				var attributes = { type: "text/javascript" };
				javascriptConfig.push( { content: content, attributes: { src: null, type: "text/javascript" } } );
			} else if (script.method == 'combine') {
				var content = File.getContent(filename);
				combined += content + "\r\n";
			} else {
				javascriptConfig.push( { attributes: { src: href, type: "text/javascript" } } );
			}
		}

		if (combined.length > 0) {
			javascriptConfig.push( { content: null, attributes: { src: "combined.js", type: "text/javascript" } } );
			File.saveContent(Path.join([ config.webserver.htdocs, 'combined.js' ]), combined);
		}
	}

	function packageCss() {
		Sys.println('Packing css');

		var stylesheets:Array<Entry> = config.css;
		var combined:String = "";
		for (css in stylesheets) {
			FileSystem.createDirectory(css.dest);
			var src = css.src[0];
			var src_href = css.href[0];
			var src_out = Path.join([css.dest, Path.withoutDirectory(src_href)]); 

			var src_min = css.src[1];
			var src_min_href = css.href[1];
			var src_min_out = src_min_href == null ? null : Path.join([css.dest, Path.withoutDirectory(src_min_href)]);

			// minify css if necessary
			if (css.minifier != null) {
				var minifier = Reflect.field(config.minifiers, css.minifier);
				var args:Array<String> = minifier.args.concat([src]);
				if (verbose) Sys.println('${minifier.proc} ${args.join(' ')} > $src_min_out');
				var minifiedOutput = From.getCommandOutputAsString(minifier.proc, args);
				File.saveContent(src_min_out, minifiedOutput);
			} else if (src_min != null) {
				if (verbose) Sys.println('cp $src_min $src_min_out');
				File.copy(src_min, src_min_out);
			}

			// copy unminified css
			if (Path.extension(src) == "scss") {
				var sass_compact = Reflect.field(config.minifiers, "sass-compact");
				var sass_compact_args:Array<String> = sass_compact.args.concat([src]);
				if (verbose) Sys.println('${sass_compact.proc} ${sass_compact_args.join(' ')} > $src_out');
				var sass_compact_output = From.getCommandOutputAsString(sass_compact.proc, sass_compact_args);
				File.saveContent(src_out, sass_compact_output);
			} else {
				if (verbose) Sys.println('cp $src $src_out');
				File.copy(src, src_out);
			}

			// create cssConfig
			var filename = compress ? src_min_out : src_out;
			if (filename == null) filename = src_out; 
			var href = compress && src_min_href != null ? src_min_href : src_href;

			if (css.method == 'embed') {
				cssConfig.push( { content: File.getContent(filename), attributes: { type: "text/css" } } );
			} else if (css.method == 'combine') {
				var content = File.getContent(filename);
				combined += content + "\r\n";
			} else {
				cssConfig.push( { attributes: { rel: "stylesheet", type: "text/css", href: href } } );
			}
		}

		if (combined.length > 0) {
			cssConfig.push( { attributes: { rel: "stylesheet", type: "text/css", href: "combined.css" } } );
			File.saveContent(Path.join([ config.webserver.htdocs, 'combined.css' ]), combined);
		}
	}
}

typedef Entry = {
	var href:Array<String>;
	var dest:String;
	//var embed:Bool;
	var minifier:String;
	var src:Array<String>;
	var method:String;
}
