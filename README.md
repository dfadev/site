# site

This is a demo of website messaging using [haxe](https://github.com/HaxeFoundation/haxe), [hxbit](https://github.com/ncannasse/hxbit), [ithril](https://github.com/benmerckx/ithril), [nodejs](https://github.com/nodejs/node), [uws](https://github.com/uWebSockets/uWebSockets), [express](https://github.com/expressjs/express) and [passport](https://github.com/jaredhanson/passport).
```
Browser <-> Websocket <-> Web Server <-> TCP Socket <-> AppServer
```

Installation:

```
haxe build.hxml
```
Autobuild on file changes:
```
yarn autobuild
```

Autorestart servers on file changes:
```
yarn start
```
