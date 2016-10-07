
# NB this might need to be rewritten to use an ID based system rather than IP address
# if the controllers/carts drop off the network too much


import socket


UDPSock = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
# Listen on port 8000 (to all IP addresses on this system)
listen_addr = ("", 3000)
UDPSock.bind(listen_addr)

controllers = []
carts = []
cartToController = []
allow_reuse_address = True

currentGameEvent = -1
currentGameEventOwner = ""


def addCart(self, address):
	print "addCart"
	self.carts.append(address)
	if(len(self.carts) > len(self.controllers) and len(self.controllers) > len(self.cartToController)):
		joint = {'cart':handler, 'cart':controllers[len(controllers)-1], 'cachedSpeed':[127, 127]}
		self.cartToController.append(joint)

def addController(self, address):
	print "addController"
	self.controllers.append(address)
	if(len(self.controllers) > len(self.cartToController) and len(self.carts) > len(self.cartToController)):
		joint = {'cart':self.carts[len(self.carts)-1], 'cart':handler, 'cachedSpeed':[127, 127]}
		self.cartToController.append(joint)

def removePair(self, address):
	try:
		for joint in self.cartToController:
			if(joint['cart'] == handler or joint['cart'] == handler):
				cartToController.remove(joint)
				return
	except NameError:
		print "no cartToController"


def routeControlSignal(self, address, message):
	for joint in self.cartToController:
		if(joint['cart'] == address):
			l,r = getSpeed(message)
			joint['cachedSpeed'][0] = l
			joint['cachedSpeed'][1] = r
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]), joint['cart'])
			return

def getColor(self, address, message):
	print "GET COLOR " + str(message)	
	for joint in self.cartToController:
		if(joint['cart'] == address):
			try:
				currentGameEvent = int(message)
				currentGameEventOwner = address
				t = Timer(2.0, clearGameState)
			except ValueError:
				print "Value error parsing color"
				return

def getSpeed(message):
	l = int(message.split(':')[1]) - 127
	r = int(message.split(':')[2]) - 127
	return l,r


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
	for joint in self.cartToController:
		if(joint['cart'].client_address != self.currentGameEventOwner):
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0]*0.5, joint['cachedSpeed'][1]*0.5), joint['cart'])
		else:
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]), joint['cart'])

def circle(self):
	for joint in self.cartToController:
		if(joint['cart'].client_address != self.currentGameEventOwner):
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0]*-1, joint['cachedSpeed'][1]*-1), joint['cart'])
		else:
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]), joint['cart'])

def skewRight(self):
	for joint in self.cartToController:
		if(joint['cart'].client_address != self.currentGameEventOwner):
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]*0.6), joint['cart'])
		else:
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]), joint['cart'])

def skewLeft(self):
	for joint in self.cartToController:
		if(joint['cart'].client_address != self.currentGameEventOwner):
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0]*0.6, joint['cachedSpeed'][1]), joint['cart'])
		else:
			UDPSock.sendto(self.stringify(joint['cachedSpeed'][0], joint['cachedSpeed'][1]), joint['cart'])

# don't think I need this for the feather
def stringify(self, left, right):
	dataString = ""

	modLeft = left + 127
	modRight = right + 127

	if modLeft < 10:
		dataString += "00" + str(modLeft)
	elif left < 100:
		dataString += "0" + str(modLeft)
	else:
		dataString += str(modLeft)

	dataString+=":"

	if right < 10:
		dataString += "00" + str(modRight)
	elif right < 100:
		dataString += "0" + str(modRight)
	else:
		dataString += str(modRight)

	return dataString

def clearGameState():
	self.currentGameEvent = -1



while True:
	data,addr = UDPSock.recvfrom(1024)

	if "register_cart" in data.strip():
		addCart(addr)
	elif "register_controller" in data.strip():
		addController(addr)
	elif "color" in data.strip():
		getColor(addr, data)
	elif "speed" in data.strip():
		routeControlSignal(addr, data)
	else:
		print "bad command"