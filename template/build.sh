#!/bin/sh
APPSRV="haxe hxml/appserver.hxml"
WEBSRV="haxe hxml/webserver.hxml"
RENDERVIEW="haxe hxml/renderview.hxml"

if [ ! -d node_modules ]; then
	site npm
fi

site hxml && haxe hxml/client.hxml && site pack && concurrently "$APPSRV" "$WEBSRV" "$RENDERVIEW" && site html
