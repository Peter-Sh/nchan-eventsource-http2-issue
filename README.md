# nginx nchan EventSource over http2 problem demostration

This docker image is based on official docker nginx:1.18 image and includes nchan module 1.2.7

## How to reproduce

### Build this docker image.

```sudo docker build -t nchan-issue .```

### Start docker image and bind ports.

Inner ports:
* 80 - is plain http
* 443 - is ssl with http2
* 444 - is ssl *without* http2

```sudo docker run --rm -p 3005:80 -p 3006:443 -p 3007:444 nchan-issue```

### Check that plain http is working

Subscribe to EventSource with curl
```curl -v -H 'Accept: text/event-stream' https://localhost:3005/subscribe/```

Publish a message to channel:
```curl -v -dmessaage http://localhost:3005/publish/```

The message should appear in the terminal where subscriber is running.

### Check http2


#### Subscribing to EventSource with http2 on http2 capable port is broken.

```curl --http2 --insecure -v -H 'Accept: text/event-stream' https://localhost:3006/subscribe/```

Expected behaviour: messages are received as in plain http.

Real behaviour: connection is closed.

Nginx logs:

```
2020/06/13 10:07:48 [error] 6#6: *1 output on closed stream, client: 172.17.0.1, server: localhost, request: "GET /subscribe/ HTTP/2.0", host: "localhost:3006"
172.17.0.1 - - [13/Jun/2020:10:07:48 +0000] "GET /subscribe/ HTTP/2.0" 400 0 "-" "curl/7.52.1" "-"
```


#### Subscribing to EventSource with http1.1 on http2 capable port is OK.

```curl --http1.1 --insecure -v -H 'Accept: text/event-stream' https://localhost:3006/subscribe/```

Messages are received when publishing to channel.

```curl -v -dmessaage http://localhost:3005/publish/```


#### Subscribing to EventSource with http1.1 on NON http2 capable port is also OK.

```curl --http1.1 --insecure -v -H 'Accept: text/event-stream' https://localhost:3007/subscribe/```

Messages are received when publishing to channel.

```curl -v -dmessaage http://localhost:3005/publish/```

### Subscribing to non event source stream over http2 is OK

Tested long polling and websocket.

### Test in browser

Open in browser:

* http://localhost:3005 (plain http)
* http://localhost:3006 (http2)
* http://localhost:3007 (ssl http1.1)

In browser console run
```
var E = new EventSource('/subscribe/');
E.addEventListener('message', function (m) { console.log(m); });
```

Then publish a message
```await (await fetch('/publish/', {method: 'POST', body: (new Date()).toString()})).text()```

* 3005 (plain http): Message is printed in the console
* 3006 (http2): Message is *not* printed in console (In network tab /subsribe/ looks like open but without any activity)
* 3007 (ssl http1.1): Message is printed in the console
