package site;

import haxe.io.Bytes;
import site.Msg;

using StringTools;

class Evt {
	static var s(get, null):hxbit.Serializer;
	static function get_s() return s = (s != null) ? s : new hxbit.Serializer();
	static var ser:Dynamic;

	static public function setup(msgType:String, handler:Dynamic) {
		ser = Type.resolveClass("hxbit.enumSer." + msgType.replace(".", "_"));
		if (ser == null) throw "No enum unserializer for " + msgType;
		handlers.push(handler);
	}

	static public function toBytes(msg, ?prependLength = false):Bytes {
		s.begin();
		if (prependLength) s.addInt32(0);// length placeholder
		ser.doSerialize(s, msg);
		var bytes = s.end();
		if (prependLength) bytes.setInt32(0, bytes.length - 4);
		return bytes;
	}

	static public function fromBytes(bytes:Bytes, ?prependLength = false) {
		s.refs = new Map();
		if (prependLength) s.setInput(bytes, 4);// skip length placeholder
		else
			s.setInput(bytes, 0);
		return ser.doUnserialize(s);
	}
#if nodejs 
	static public function asBuffer(msg, ?prependLength = false) return js.node.Buffer.hxFromBytes(toBytes(msg, prependLength));
#end

	static public function handleMessage(?srcId:Int, ?destId:Int, data:Bytes, ?prependLength = false) {
		try {
			var msg = fromBytes(data, prependLength);
			if (msg == null)
			{
				emit(Error("nullmsg"));
				throw "nullmsg";
			}
			else
				emit(DataMessage(srcId, destId, msg));
		} catch (e:Dynamic) {
			emit(Error(e));
		}
	}

	static var handlers = new Array<Msg<Dynamic>->Void>();
	public static function emit(msg) for (handler in handlers) { handler(msg); };
}
