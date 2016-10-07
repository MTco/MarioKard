import struct
import SocketServer
import time
import threading
from threading import Timer
from SocketServer import ThreadingTCPServer, BaseRequestHandler
from base64 import b64encode
from hashlib import sha1
from mimetools import Message
from StringIO import StringIO
import timeit

LEFT = 0
RIGHT = 1

class WebSocketsHandler(SocketServer.StreamRequestHandler):
    magic = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
    hasSecKey = True
    receivedMessage = ""

    def setup(self):
        SocketServer.StreamRequestHandler.setup(self)
        print "connection established", self.client_address
        self.handshake_done = False

    def handle(self):
        while True:
            if not self.handshake_done:
		print "handshake"
                self.handshake()
            else:
                self.read_next_message()
                #time.sleep(5)

    def read_next_message(self):
        if self.hasSecKey:
            try:
                length = ord(self.rfile.read(2)[1]) & 127
            except IndexError:
                self.server.removePair(self)
		return

            if length == 126:
                length = struct.unpack(">H", self.rfile.read(2))[0]
            elif length == 127:
                length = struct.unpack(">Q", self.rfile.read(8))[0]

            masks = [ord(byte) for byte in self.rfile.read(4)]
            decoded = ""
            for char in self.rfile.read(length):
                decoded += chr(ord(char) ^ masks[len(decoded) % 4])
            self.on_message(decoded)
        else:
            self.on_message(self.rfile.read(8))

    def send_message(self, message):
        print "sending"
        print message
        if self.hasSecKey:
            self.request.send(chr(129))
            length = len(message)
            if length <= 125:
                self.request.send(chr(length))
            elif length >= 126 and length <= 65535:
                self.request.send(126)
                self.request.send(struct.pack(">H", length))
            else:
                self.request.send(127)
                self.request.send(struct.pack(">Q", length))
            self.request.send(message)
        else:
            self.request.send('\x00' + message + '\xff')

    def handshake(self):
	print "handshake"
        data = self.request.recv(1024).strip()
        dSplit = data.split('\r\n', 1)
        if len(dSplit) > 1 :
            headers = Message(StringIO(data.split('\r\n', 1)[1]))
        else:
            headers = Message(StringIO(data.split('\r\n', 1)))

        if headers.get("Upgrade", None) == None:
            return

        if headers.get("Upgrade", None).lower() != "websocket":
            return

        try:
            key = headers['Sec-WebSocket-Key']
            digest = b64encode(sha1(key + self.magic).hexdigest().decode('hex'))
            print "has key"
        except KeyError:
            self.hasSecKey = False
            print "no Sec-WebSocket-Key"

        response = 'HTTP/1.1 101 Switching Protocols\r\n'
        response += 'Upgrade: websocket\r\n'
        response += 'Connection: Upgrade\r\n'

        #this is also where we can distinguish a wifly from a browers
        if(self.hasSecKey):
            response += 'Sec-WebSocket-Accept: %s\r\n\r\n' % digest

        print "sending back handshake"
        self.handshake_done = self.request.send(response)
        if(self.hasSecKey):
            self.server.addBrowser(self)
        else:
            self.server.addWiFly(self)

    def on_message(self, message):
        self.receivedMessage += message.strip("\r")
        # here's where we break out our messages
        # only browsers send a security key
        if(self.hasSecKey):
            #make sure we have at least a whole message
            #if self.receivedMessage.find("left") != -1 and len(self.receivedMessage) > 6:
            #    self.receivedMessage = self.receivedMessage[self.receivedMessage.index("left"):len(self.receivedMessage)]
            #    self.server.routeControlSignal(self, self.receivedMessage, LEFT)
            #    self.receivedMessage = ""

            #make sure we have at least a whole message
            #if self.receivedMessage.find("right") != -1 and len(self.receivedMessage) > 7:
            #    self.receivedMessage = self.receivedMessage[self.receivedMessage.index("right"):len(self.receivedMessage)]
            #    self.server.routeControlSignal(self, self.receivedMessage, RIGHT)
            #    self.receivedMessage = ""
	

	    if  len(self.receivedMessage) > 6:
		lspeed = self.receivedMessage[0:3] # don't mess with negative numbers
		self.server.routeControlSignal(self, lspeed, LEFT)
		rspeed = self.receivedMessage[4:7] # don't mess with negative numbers
		print " speed " + str(lspeed) + " " + str(rspeed)
		self.server.routeControlSignal(self, rspeed, RIGHT)
                self.receivedMessage = ""

        else:

	    if self.receivedMessage.find("color:") != -1 and len(self.receivedMessage) > 7:
		print "Received a color " + self.receivedMessage
                colorSent = self.receivedMessage.split(':')[1]
		print "color sent = " + colorSent
                self.server.getColor(self, colorSent[0])
	        self.receivedMessage = ""
	    elif  len(self.receivedMessage) > 6:
		lspeed = self.receivedMessage[0:3] # don't mess with negative numbers
		self.server.routeControlSignal(self, lspeed, LEFT)
		rspeed = self.receivedMessage[4:7] # don't mess with negative numbers
		print " speed " + str(lspeed) + " " + str(rspeed)
		self.server.routeControlSignal(self, rspeed, RIGHT)
                self.receivedMessage = ""
		

class WSServer(ThreadingTCPServer):

    browserClients = []
    wiflyClients = []
    jointBrowserWifly = []
    allow_reuse_address = True

    currentGameEvent = -1
    currentGameEventOwner = ""

    def handle_request(self):
        print " handle request "
        handler = ThreadingTCPServer.handle_request(self)
        handler.set_handlers(self.handleWiFlyMessage, self.handleBrowserMessage)
        return handler

    def finish_request(self, *args, **kws):
        print "process request"
        handler = ThreadingTCPServer.finish_request(self, *args, **kws)

    def addWiFly(self, handler):
        print "handleWiFlyMessage"
        self.wiflyClients.append(handler)
        if(len(self.wiflyClients) > len(self.browserClients) and len(self.browserClients) > len(self.jointBrowserWifly)):
            joint = {'wifly':handler, 'browser':browserClients[len(browserClients)-1], 'cachedSpeed':[122, 122]}
            self.jointBrowserWifly.append(joint)

    def addBrowser(self, handler):
        print "handleBrowserMessage"
        self.browserClients.append(handler)
        if(len(self.browserClients) > len(self.jointBrowserWifly) and len(self.wiflyClients) > len(self.jointBrowserWifly)):
            joint = {'wifly':self.wiflyClients[len(self.wiflyClients)-1], 'browser':handler, 'cachedSpeed':[122, 122]}
            self.jointBrowserWifly.append(joint)

    def removePair(self, handler):
        try:
            for joint in self.jointBrowserWifly:
                if(joint['browser'] == handler or joint['wifly'] == handler):
                    jointBrowserWifly.remove(joint)
                    return
        except NameError:
            print "no jointBrowserWifly"


    def routeControlSignal(self, handler, message, side):
        

        for joint in self.jointBrowserWifly:
            if(joint['browser'] == handler):
                joint['cachedSpeed'][side] = int(message)
                joint['wifly'].send_message(self.stringify(joint['cachedSpeed'][LEFT], joint['cachedSpeed'][RIGHT]))
                return

    def getColor(self, handler, message):
	print "GET COLOR " + str(message)	
        for joint in self.jointBrowserWifly:
            if(joint['wifly'] == handler):
		try:
                	currentGameEvent = int(message)
			currentGameEventOwner = handler.client_address
	                t = Timer(2.0, clearGameState)
		except ValueError:
			print "Value error parsing color"		
                return

    def gameUpdate(self):

        if self.currentGameEvent == 1:
            self.slowDown()
        elif self.currentGameEvent == 2:
            self.circle()
        elif self.currentGameEvent == 3:
            self.skewRight()
        elif self.currentGameEvent == 4:
            self.skewLeft()


    def slowDown(self):
        for joint in self.jointBrowserWifly:
            if(joint['wifly'].client_address != self.currentGameEventOwner):
                joint['wifly'].send_message( self.stringify(joint['cachedSpeed'][0]*0.9, joint['cachedSpeed'][1]*0.9))
            else:
                joint['wifly'].send_message( self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]))

    def circle(self):
        for joint in self.jointBrowserWifly:
            if(joint['wifly'].client_address != self.currentGameEventOwner):
                joint['wifly'].send_message( self.stringify(joint['cachedSpeed'][0]*-0.9, joint['cachedSpeed'][1]*0.9))
            else:
                joint['wifly'].send_message( self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]))

    def skewRight(self):
        for joint in self.jointBrowserWifly:
            if(joint['wifly'].client_address != self.currentGameEventOwner):
                joint['wifly'].send_message( self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]*0.9))
            else:
                joint['wifly'].send_message( self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]))

    def skewLeft(self):
        for joint in self.jointBrowserWifly:
            if(joint['wifly'].client_address != self.currentGameEventOwner):
                joint['wifly'].send_message( self.stringify(joint['cachedSpeed'][0]*0.9, joint['cachedSpeed'][1]))
            else:
                joint['wifly'].send_message( self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]))

    def stringify(self, left, right):
        dataString = ""
        if left < 10:
            dataString += "00" + str(left)
        elif left < 100:
            dataString += "0" + str(left)
        else:
            dataString += str(left)

        dataString+=":"

        if right < 10:
            dataString += "00" + str(right)
        elif right < 100:
            dataString += "0" + str(right)
        else:
            dataString += str(right)

        return dataString

    def clearGameState():
        self.currentGameEvent = -1

if __name__ == "__main__":
    server = WSServer(("", 3000), WebSocketsHandler)

    server_thread = threading.Thread(target=server.serve_forever)
    ip, port = server.server_address

    server_thread.setDaemon(True)
    server_thread.start()

    print str(ip) + ' ' + str(port)

    while 1:
        num = 0

    server_thread.join()
    server.shutdown()

