package model;

@:build(site.Serializable.build())
enum NetworkMessage {
	Hello(world:String);
}
