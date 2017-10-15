package site.net;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

class TcpServer extends cpp.net.ThreadServer<TcpConnection, Array<Bytes>> {
	static var srv:TcpServer;
	public static function execute(config:TcpServerConfiguration) {
		srv = new TcpServer(config.listen.host, config.listen.port);
		srv.exec();
	}

	var host:String;
	var port:Int;

	var connections:Array<TcpConnection> = new Array<TcpConnection>();

	function new(host:String, port:Int) {
		super();
		this.host = host;
		this.port = port;
		DataMessage.emit(Starting);
	}

	function exec() { run(host, port); return this; }

	override function clientConnected(sockt) {
		var cnx = new TcpConnection();
		cnx.socket = sockt;
		cnx.id = connections.push(cnx) - 1;

		sockt.setFastSend(true);
		DataMessage.emit(Connected(cnx));
		return cnx;
	}

	override function clientDisconnected(cnx:TcpConnection):Void {
		DataMessage.emit(Disconnected(cnx));
		connections[cnx.id] = null;
	}

	override function run(host, port) {
		sock = new sys.net.Socket();
		sock.bind(new sys.net.Host(host), port);
		sock.listen(listen);
		init();
		DataMessage.emit(Started);
		while(true) {
			try { addSocket(sock.accept()); }
			catch(e : Dynamic) { logError(e); }
		}
	}

	override function onError(e, stack) DataMessage.emit(Error([e, stack]));

	override function readClientMessage(cnx:TcpConnection, buf:Bytes, start:Int, length:Int) {
		var rslt = cnx.readClientMessage(buf, start, length);
		if (cnx.error) cnx.socket.close();
		return rslt;
	}

	override function clientMessage(from:TcpConnection, msg:Array<Bytes>) {
		if (msg == null) return;
		for (m in msg) DataMessage.handleMessage(from.id, m, true);
	}

	public static function send(id, msg) {
		var cnx = srv.connections[id];

		if (cnx == null) return;
		var data = DataMessage.toBytes(msg, true);
		try { cnx.socket.output.writeFullBytes(data, 0, data.length); }
		catch (e:Dynamic) { DataMessage.emit(Error(e)); }
	}
}

typedef TcpServerConfiguration = {
	listen:TcpServerListenOptions
}

typedef TcpServerListenOptions = {
	host:String,
	port:Int,
}
