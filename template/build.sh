#!/bin/sh
CLIENT="haxe hxml/client.hxml && site pack"
APPSRV="haxe hxml/appserver.hxml"
WEBSRV="haxe hxml/webserver.hxml"
RENDERVIEW="haxe hxml/renderview.hxml"

site hxml
concurrently "$CLIENT" "$APPSRV" "$WEBSRV" "$RENDERVIEW"
site html
