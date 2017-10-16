package site.net;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
#if nodejs
import js.node.net.Socket;
import js.node.Buffer;
#end

class TcpConnection {
	public var id:Int;
#if sys
	public var socket:sys.net.Socket;
#end
	public var error:Bool;
	var curPos:Int;
	var lenBytes:Bytes = Bytes.alloc(4);
	var len:Int;
	var b:BytesOutput;
	var gotLength:Bool;
	public static inline var maxMessageSize:Int = 1024 * 1024 * 15;

	public function new() reset();

	function reset() {
		b = new BytesOutput();
		curPos = 0;
		len = 0;
		gotLength = false;
		error = false;
	}

	public function readClientMessage(buf:Bytes, start:Int, length:Int) {
		var messages = new Array<Bytes>();

		var data = buf.getData();
		var idx = start;
		var end = start + length;

		while (idx < end) {
			if (!gotLength) {
				for (pos in idx ... end) {
					var c = Bytes.fastGet(data, pos);
					lenBytes.set(curPos, c);
					curPos++;
					if (curPos == 4) {
						len = lenBytes.getInt32(0);
						gotLength = true;
						b.writeInt32(len);
						idx = pos + 1;
						break;
					}
				}
				if (!gotLength) return { msg:null, bytes: length };
			}

			if (len < 0 || len > maxMessageSize) {
				error = true;
				return { msg: null, bytes: length };
			}

			for (pos in idx ... end) {
				var c = Bytes.fastGet(data, pos);
				b.writeByte(c);
				len--; idx++;
				if (len == 0) {
					messages.push(b.getBytes());
					reset();
					break;
				}
			}
		}

		return { msg: (messages.length > 0) ? messages : null, bytes: idx - start };
	}

#if sys
	public function send(msg) {
		var data = Evt.toBytes(msg, true);
		try { socket.output.writeFullBytes(data, 0, data.length); }
		catch (e:Dynamic) { Evt.emit(Error(e)); }
	}
#end
}
