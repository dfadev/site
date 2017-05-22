package site;

import js.npm.uws.WebSocket;

class WebSocketServer {
	static var opts = { binary: true };
	static var sockets = new Map<Int, WebSocket>();
	static var wss:js.npm.uws.WebSocketServer;
	static var idCounter = 0;
	static inline function getNextId() return ++ idCounter;

	static public function execute(http) {
		wss = new js.npm.uws.WebSocketServer( { server: http } );

		wss.on('connection', function connection(socket:WebSocket) {
			socket.id = getNextId();
			sockets[socket.id] = socket;

			socket.req = {
				originalUrl: socket.upgradeReq.originalUrl,
				url: socket.upgradeReq.url,
				headers: { cookie: socket.upgradeReq.headers.cookie },
				logout: socket.upgradeReq.logout,
				logIn: socket.upgradeReq.logIn,
				isAuthenticated: socket.upgradeReq.isAuthenticated,
				session: socket.upgradeReq.session,
				user: socket.upgradeReq.user
			};

			socket.on('close', function () {
				close(socket);
				if (sockets[socket.id] != null) {
					sockets.remove(socket.id);
					DataMessage.emit(Disconnected(socket));
				}
			});

			WebServer.checkSocketAuth(socket.req, function(err) {
				socket.on('message', function (msg:js.node.Buffer) DataMessage.handleMessage(socket.id, socket.id, msg.hxToBytes()));
				DataMessage.emit(Connected(socket));
			});
		});
	}

	static public function close(socket:WebSocket) {
		if (sockets[socket.id] != null) {
			sockets.remove(socket.id);
			DataMessage.emit(Disconnected(socket));
		}
	}

	static public function send(id, msg) {
		var socket = sockets[id];
		if (socket == null || socket.readyState != 1) return;
		var data = DataMessage.asBuffer(msg);
		try { socket.send(data, opts); }
		catch (e:Dynamic) {
			DataMessage.emit(Error(e));
			close(socket);
		}
	}

	static public function broadcast(msg) {
		var data = DataMessage.asBuffer(msg);
		for (socket in sockets) {
			if (socket == null || socket.readyState != 1) continue;
			try { socket.send(data, opts); }
			catch (e:Dynamic) {
				DataMessage.emit(Error(e));
				close(socket);
			}
		}
	}
}
