class App {
	static function main() Site.run("model.NetworkMessage", function (e) controller.Handler.handle(NetworkEvent(e)));
}
