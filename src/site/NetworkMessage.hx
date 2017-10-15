package site;

import haxe.macro.Context;
import haxe.macro.Expr;

class NetworkMessage {

	macro public function build():Array<Field> {
		var fields = Context.getBuildFields();
#if (!browser || site_websocket)
		makeType(["msg"], "NetworkMessageStub");
#end
		return fields;
	}

#if macro
    static function makeType(pack:Array<String>, className:String)
    {
        var pos = Context.currentPos();

        var cdef = macro 
			class NetworkMessageStub implements hxbit.Serializable { @:s public var n:model.NetworkMessage; }

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
