package site;

import haxe.macro.Context;
import haxe.macro.Expr;

class Serializable {

	//stub a @:keep class so the enum serializer gets built
	macro public function build():Array<Field> {
		var fields = Context.getBuildFields();

#if (!browser || site_websocket)
		var localType = Context.getLocalType();
		switch (localType) {
			case TEnum(rt, p):
				var t = rt.get();
				makeType(["msg"], t.name + "Stub");
			default:
				throw "can't build stub for type " + localType;
		}
#end
		return fields;
	}

#if macro
    static function makeType(pack:Array<String>, className:String)
    {
        var pos = Context.currentPos();

        var cdef = macro class $className implements hxbit.Serializable { @:s public var n:model.NetworkMessage; }

        cdef.pack = pack.copy();
        cdef.name = className;

        cdef.meta = [{
            name: ':keep',
            params: [],
            pos: pos
        }];

        haxe.macro.Context.defineType(cdef);

        return {
            expr:EConst(CIdent(className)),
            pos:pos
        };
    }
#end
}
