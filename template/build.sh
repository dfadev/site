#!/bin/sh
APPSRV="haxe hxml/default/appserver.hxml"
WEBSRV="haxe hxml/default/webserver.hxml"
RENDERVIEW="haxe hxml/default/renderview.hxml"

if [ ! -d node_modules ]; then
	site npm
fi

site hxml && haxe hxml/default/client.hxml && site pack && concurrently "$APPSRV" "$WEBSRV" "$RENDERVIEW" && site html && haxe hxml/default/ctags.hxml
