require 'pyramid/logging'
require 'sequel'
require 'mysql2'

module Pyramid
  module Database
    include Pyramid::Logging

    Sequel::Model.plugin :timestamps, update_on_create: true
    Sequel::Model.plugin :json_serializer, naked: true
    Sequel::Model.raise_on_save_failure = true
    Sequel.extension :pagination
    Sequel.application_timezone = :utc
    Sequel.database_timezone = :utc

    class << self
      def config(env = ENV['RACK_ENV'])
        env = env.to_sym
        @config ||= {}
        @config[env] ||= YAML.load_file(File.join('.', 'config', 'database.yml'))[env.to_s]
      end

      def migrations_dir
        File.join('.', 'db', 'migrations')
      end

      def url
        sprintf("mysql2://%s:%s@%s/%s", config['username'], config['password'], config['host'], config['database'])
      end

      def connect!(options = {})
        connect_options = {
          user:         config['username'],
          password:     config['password'],
          host:         config['host'],
          database:     config['database'],
          encoding:     config['encoding'],
          pool_timeout: config['timeout'],
          single_threaded: true,
          max_connections: 1,
          after_connect: lambda {|conn| logger.debug "Connected to db with connection #{conn.inspect}"}
        }
        connect_options[:loggers] = [Pyramid.logger] unless options[:silence_logging]
        @db = Sequel.mysql2(connect_options)
      end

      def db
        @db
      end

      def disconnect!
        @db.disconnect if @db
      end

      def silence_logging(&block)
        old_loggers = connection.loggers
        connection.loggers = []
        begin
          yield
        ensure
          connection.loggers = old_loggers
        end
      end
    end
  end
end
