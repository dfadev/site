package site;

enum SiteMessage<T> {

#if webserver

	Connected(cnx:js.npm.uws.WebSocket);
	Disconnected(cnx:js.npm.uws.WebSocket);
	ServerConnected(proxy:TcpClient);
	ServerDisconnected(proxy:TcpClient);

#elseif browser

	Connected(cnx:js.html.WebSocket);
	Disconnected(cnx:js.html.WebSocket);

#elseif appserver

	Connected(cnx:TcpConnection);
	Disconnected(cnx:TcpConnection);

#end

	DataMessage(?srcId:Int, ?destId:Int, msg:T);
	Error(e:Dynamic);
}
