package site;

class WebSocketClient {
	static var websocket:js.html.WebSocket;
	static var reconnectDelay:Int = 0;
	static public function execute(config:WebSocketConfiguration) {
		websocket = new js.html.WebSocket(config.url, ['echo-protocol']);
		websocket.binaryType = ARRAYBUFFER;
		websocket.onopen = function (e) {
			reconnectDelay = Std.int(config.reconnect.minimumDelay);
			DataMessage.emit(Connected(websocket));
		}
		websocket.onmessage = function (msg) DataMessage.handleMessage(haxe.io.Bytes.ofData(msg.data));
		websocket.onerror = function(msg) DataMessage.emit(Error(msg));
		websocket.onclose = function() {
			DataMessage.emit(Disconnected(websocket));
			haxe.Timer.delay(function () {
				reconnectDelay += Std.int(config.reconnect.step);
				if (reconnectDelay > Std.int(config.reconnect.maximumDelay))
					reconnectDelay = Std.int(config.reconnect.minimumDelay);
				execute(config);
			}, reconnectDelay);
		};
	}

	static public function send(msg) {
		if (websocket == null) { DataMessage.emit(Error('websocket == null')); return; }
		if (websocket.readyState != 1) { DataMessage.emit(Error('websocket readyState == ${websocket.readyState}')); return; }

		try {
			var msgData = DataMessage.toBytes(msg);
			websocket.send(msgData.getData());
		}
		catch (e:Dynamic) {
			DataMessage.emit(Error(e));
		}
	}
}
