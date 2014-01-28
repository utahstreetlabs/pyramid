require 'pyramid/database'

configure do
  set :database, Pyramid::Database.connect!
end
