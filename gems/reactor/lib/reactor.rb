require_relative 'reactor/packet'
require_relative 'reactor/selector'
require_relative 'reactor/socket_handler'
require_relative 'reactor/socket_factory'

$selector = Selector.new