function opt82_dlink(pkt)
	v,b1,b2,b3,b4=string.unpack(pkt:agent_remote_id():sub(-4),'bbbb')
	ip=b1..'.'..b2..'.'..b3..'.'..b4
	v,port=string.unpack(string.sub(pkt:agent_circuit_id(),'-1'),'b')
	local opt82=ip..'-'..port
--    print(opt82)
	return opt82
end
function example(ses)
--	print('xid='..ses:hdr('xid'))
--	print('ciaddr='..ses:hdr('ciaddr'))
--	print('giaddr='..ses:hdr('giaddr'))
--	print('chaddr='..ses:hdr('chaddr'))
--	print('ifname='..ses:ifname())
--	options=ses:options()
--	for k,opt in ipairs(options) do print(opt) end
	return '1234'
end
function ifname(pkt)
	local ifname=pkt:ifname()
	return ifname
end
function mac(pkt)
	local mac=pkt:hdr("chaddr")
	return mac
end
function qinq(pkt)
	local qinq = string.sub(pkt:ifname(), string.find(pkt:ifname(), ".", 1, true)+1, 32)
	return qinq
end

