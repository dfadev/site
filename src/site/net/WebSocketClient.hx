package site.net;

import site.Msg;

class WebSocketClient {
	static var websocket:js.html.WebSocket;
	static var reconnectDelay:Int = 0;
	static public function execute(config:WebSocketConfiguration) {
		websocket = new js.html.WebSocket(config.url, ['echo-protocol']);
		websocket.binaryType = ARRAYBUFFER;
		websocket.onopen = function (e) {
			reconnectDelay = Std.int(config.reconnect.minimumDelay);
			Evt.emit(Connected(websocket));
		}
		websocket.onmessage = function (msg) Evt.handleMessage(haxe.io.Bytes.ofData(msg.data));
		websocket.onerror = function(msg) Evt.emit(Error(msg));
		websocket.onclose = function() {
			Evt.emit(Disconnected(websocket));
			haxe.Timer.delay(function () {
				reconnectDelay += Std.int(config.reconnect.step);
				if (reconnectDelay > Std.int(config.reconnect.maximumDelay))
					reconnectDelay = Std.int(config.reconnect.minimumDelay);
				execute(config);
			}, reconnectDelay);
		};
	}

	static public function send(msg) {
		if (websocket == null) { Evt.emit(Error('websocket == null')); return; }
		if (websocket.readyState != 1) { Evt.emit(Error('websocket readyState == ${websocket.readyState}')); return; }

		try {
			var msgData = Evt.toBytes(msg);
			websocket.send(msgData.getData());
		}
		catch (e:Dynamic) {
			Evt.emit(Error(e));
		}
	}
}

typedef WebSocketConfiguration = {
	url:String,
	reconnect:{ minimumDelay:Int, maximumDelay:Int, step:Int }
}
