module ServerID
	GATE	= 1
	CENTER	= 2
	LOGIC	= 3
	DISPATCHER = 4
end

module ServerIP
	GATE	= ['127.0.0.1', 7410]
	CENTER	= ['127.0.0.1', 2501]
end

module ControlMsgID
	SET_ID = 1
	FORCE_CLOSE = 2
end