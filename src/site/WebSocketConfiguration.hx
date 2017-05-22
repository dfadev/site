package site;

typedef WebSocketConfiguration = {
	url:String,
	reconnect:{ minimumDelay:Int, maximumDelay:Int, step:Int }
}


