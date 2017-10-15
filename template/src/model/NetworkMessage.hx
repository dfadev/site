package model;

@:build(site.NetworkMessage.build())
enum NetworkMessage {
	Hello(world:String);
}
