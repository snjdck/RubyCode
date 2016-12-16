require_relative "lib/server"

p "aa".hash
p :vfg.hash
p :aabbccddeeff.hash
=begin
p = Packet.new
puts p.msgId
puts p.msgData
p p.to_s
=end
t = 1
while t < 5
	p t
	t += 1
end

gets
return

t = {}
p t
t[:a] = 1
p t
t[:a] = nil
p t
module Fuck
class << Fuck
	def a
	end
end
end
p :a.hash
p 1.hash
gets
return
def ff a=nil
end
m = method :ff
p m.parameters
m = method :callcc
p m
gets
return
Packet.control 1, [2,3,4,5]

module A
	@@t = {1 => :a}
	def t
		@@t
	end
	def aa *arg
		p arg
	end
end
class C
	include A
end
class D
	include A
end
p C.new.t.object_id
p D.new.t.object_id
p C.new.t.equal? D.new.t
D.new.aa 1 do
	puts "fuck"
end

=begin
a = [1,2,3,4,nil]
b = a.pack 'n4a*'
t1, t2, t3, t4, t5 = b.unpack 'n4a*'
p b
p t1, t2, t3, t4, t5
=end
gets