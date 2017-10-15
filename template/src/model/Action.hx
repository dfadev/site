package model;

import site.net.SiteMessage;

enum Action {
	NetworkEvent(msg:SiteMessage<NetworkMessage>);
}

