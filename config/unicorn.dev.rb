$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'pyramid/database'

worker_processes 1
preload_app true
timeout 30

before_fork do |server, worker|
  Pyramid::Database.disconnect!
end

after_fork do |server, worker|
  Pyramid::Database.connect!
end
