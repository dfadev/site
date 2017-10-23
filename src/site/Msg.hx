package site;

import site.net.*;

enum Msg<T> {

#if webserver

	Connected(cnx:js.npm.uws.WebSocket);
	Disconnected(cnx:js.npm.uws.WebSocket);
	ServerConnected(proxy:BackEnd);
	ServerDisconnected(proxy:BackEnd);

#elseif browser

	Connected(cnx:js.html.WebSocket);
	Disconnected(cnx:js.html.WebSocket);

#elseif appserver

	Connected(cnx:TcpConnection);
	Disconnected(cnx:TcpConnection);

#end

	Starting();
	Started();
	DataMessage(?srcId:Int, ?destId:Int, msg:T);
	Error(e:Dynamic);
}
