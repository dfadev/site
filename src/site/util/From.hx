package site.util;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class From
{
  macro public static inline function file(path:String) return toExpr(loadFileAsString(path));

	macro public static inline function command(cmd:String, ?args:Array<String>) return toExpr(getCommandOutputAsString(cmd, args));

	public static macro inline function define(key:String, defaultValue:String = null):Expr
	{
		var value = haxe.macro.Context.definedValue(key);
		if (value == null) value = defaultValue;
		return macro $v{value};
	}

  macro public static function json(path:String, rootNode:String = null) { //:ExprOf<{}> {
    var content = loadFileAsString(path);
    var obj = try haxe.Json.parse(content) catch (e:Dynamic) {
      haxe.macro.Context.error('Json from $path failed to validate: $e', Context.currentPos());
    }
    if (rootNode != null) obj = Reflect.field(obj, rootNode);
    removeMeta(obj);
    return toExpr(untyped obj);
  }

	static public function removeMeta(obj) {
		var queue = [ obj ];
		var cnt = 0;
		while (queue.length > 0) {
			var obj = queue.pop();
			var fields = Reflect.fields(obj);
			for (i in 0...fields.length) {
				var prop = fields[i];
				if (prop == '>>>' || prop == '//')
					Reflect.deleteField(obj, prop);
				else {
					var field = Reflect.field(obj, prop);
					if (Type.typeof(field) == TObject)
						queue.push(field);
				}
			}
		}
	}

	#if macro
	static function toExpr(v:Dynamic) return Context.makeExpr(v, Context.currentPos());

	static public function loadFileAsString(path:String) return sys.io.File.getContent(Context.resolvePath(path));
	#end

#if sys
	static public function getCommandOutputAsString(cmd:String, ?args:Array<String>)
	{
		try
		{
			var process = new sys.io.Process(cmd, args == null ? [] : args);
			var rslt = process.stdout.readAll().toString();
			var err = process.stderr.readAll().toString();
			var exitCode = process.exitCode(true);
			if (exitCode == 0) return rslt;
			throw '($exitCode) $err';
		}
		catch (e:Dynamic)
		{
#if macro
			return haxe.macro.Context.error('$e', Context.currentPos());
#else
			throw e;
#end
		}
	}
#end


	//public macro static function js(file:String) {
//#if !compress
		//return macro { 
			//content: ${toExpr(loadFileAsString(file))}, 
			//attributes: { type: "text/javascript" } 
		//};
//#else
//#if uglifyjs
		//return macro {
			//content: ${toExpr(getCommandOutputAsString('uglifyjs', [ '--compress', '--mangle', '--', file ]))},
			//attributes: { type: "text/javascript" }
		//};
//#else
		//return macro {
			//content: ${toExpr(getCommandOutputAsString('closure-compiler', [ '-O', '-SIMPLE', file ]))},
			//attributes: { type: "text/javascript" }
		//};
//#end
//#end
	//}

	//public macro static function uglifyjs(files:Array<String>) {
		//return macro {
			//content: ${toExpr(getCommandOutputAsString('uglifyjs', [ '--compress', '--mangle', '--' ].concat(files)))},
			//attributes: { type: "text/javascript" }
		//};
	//}

	//public macro static function closure(file:String) {
		//return macro {
			//content: ${toExpr(getCommandOutputAsString('closure-compiler', [ '-O', '-SIMPLE', file ]))},
			//attributes: { type: "text/javascript" }
		//};
	//}

	//public macro static function sassc(file:String) {
		//return macro {
			//content: ${toExpr(getCommandOutputAsString('sass', [ '--style', 'compressed', file ]))},
			//attributes: { type: "text/css" }
		//};
	//}

	//public macro static function sass(file:String) {
//#if !compress
		//return macro {
			//content: ${toExpr(getCommandOutputAsString('sass', [ '--style', 'compact', file ]))},
			//attributes: { type: "text/css" }
		//};
//#else
		//return macro {
			//content: ${toExpr(getCommandOutputAsString('sass', [ '--style', 'compressed', file ]))},
			//attributes: { type: "text/css" }
		//};
//#end
	//}
}
