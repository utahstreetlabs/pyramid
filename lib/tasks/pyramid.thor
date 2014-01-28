require 'bundler'
require 'yaml'

# Bundler >= 1.0.10 uses Psych YAML, which is broken, so fix that.
# https://github.com/carlhuda/bundler/issues/1038
YAML::ENGINE.yamler = 'syck'

Bundler.require

$LOAD_PATH << File.join(File.dirname(__FILE__), '..')

ENV['RACK_ENV'] ||= 'development'

class PyramidCli < Thor
  namespace :pyramid

  desc 'db_create', 'create the database in the current environment'
  def db_create
    run_command sprintf(%Q/mysql -h %s -u root -p -e "create database %s"/, cfg['host'], cfg['database'])
    run_command sprintf(%Q/mysql -h %s -u root -p -e "grant all privileges on %s.* to %s@'%%'"/, cfg['host'],
      cfg['database'], cfg['username'])
  end

  desc 'db_drop', 'drop the database in the current environment'
  def db_drop
    run_command sprintf(%Q/mysql -h %s -u root -p -e 'drop database %s'/, cfg['host'], cfg['database'])
  end

  desc 'db_migrate', 'run database migrations in the current environment'
  method_option :version, desc: 'migrate to this specific version rather than the latest one'
  def db_migrate
    require 'pyramid/database'
    command = %Q/sequel -m #{Pyramid::Database.migrations_dir} #{Pyramid::Database.url}/
    command << " -M #{options.version}" if options.version
    run_command command
  end

  desc "rebuild_development_db_from_staging", "copies staging db data to development db"
  def rebuild_from_staging
    db_drop
    db_create
    dev = cfg('development')
    st = cfg('staging')
    dump_command = "ssh estaging1.copious.com 'mysqldump -u #{st['username']} -p#{st['password']} -h #{st['host']} #{st['database']}'"
    load_command = "mysql -u #{dev['username']} -p#{dev['password']} -h #{dev['host']} #{dev['database']}"
    run_command("#{dump_command} | #{load_command}")
  end

  desc "dump_likes", "export likes from lagunitas to a dump file"
  method_option :host, default: '127.0.0.1'
  method_option :port, default: 27017
  method_option :db
  method_option :outfile, default: 'likes.csv'
  method_option :since, desc: 'dump only likes created since this time, as a formatted string'
  def dump_likes
    db = options.db || "lagunitas_#{env}"
    command = sprintf(%Q/mongoexport --host %s:%s --db %s --collection likes --csv --fields '%s' --out %s/,
      options.host, options.port, db, 'user_id,listing_id,tag_id,created_at,updated_at', options.outfile)
    if options.since
      require 'active_support/core_ext'
      since = DateTime.parse(options.since).utc
      since = since.to_i*1000 # mongo expects this, wtf, i dunno
      command << sprintf(%Q/ --query "{created_at:{'\\$gte':new Date(%d)}}"/, since)
    end
    run_command command
  end

  desc "import_anchor_tag_likes", "import tag likes from anchor"
  method_option :anchor_host, default: '127.0.0.1', desc: "source host for likes (anchor)"
  method_option :anchor_port, default: 27017, desc: "port on source host for likes (anchor)"
  def import_anchor_tag_likes
    require 'mongo'
    require 'pyramid/database'
    Pyramid::Database.connect!(silence_logging: true) # logging gets in the way of the progress bar

    require 'pyramid/models/like'
    Pyramid::Like.raise_on_save_failure = true

    anch_conn = Mongo::Connection.new(options.anchor_host, options.anchor_port, slave_ok: true)
    anch_db = anch_conn.db("anchor_#{ENV['RACK_ENV']}")

    count = anch_db.collection('tags').count
    say_trace "Importing #{count} likes to #{Pyramid::Database.url} from anchor"

    require 'progress_bar'
    progress = ProgressBar.new(count)

    anch_db.collection('tags').find.each do |tag|
      if tag['likes']
        tag['likes'].each do |like|
          user_id = like['user_id']
          created_at = like['created_at']
          updated_at = like['updated_at']
          tag_id = tag['tag_id'] if tag.has_key?('tag_id')
          next unless tag_id
          begin
            Pyramid::Like.create(user_id: user_id, tag_id: tag_id, created_at: created_at, updated_at: updated_at)
          rescue Pyramid::Like::DuplicateLike
            # achieve idempotence by ignoring duplicate errors
          rescue Exception => e
            say_trace "Exception creating like: #{e.message}"
          end
        end
      end
      progress.increment!
    end
  end

  desc "import_likes", "import likes from dump file"
  method_option :infile, default: 'likes.csv'
  def import_likes
    require 'pyramid/database'
    Pyramid::Database.connect!(silence_logging: true) # logging gets in the way of the progress bar

    require 'pyramid/models/like'
    Pyramid::Like.raise_on_save_failure = true

    count = `wc -l #{options.infile}`.strip.split(' ').first.to_i - 1 # account for header row
    say_trace "Importing #{count} likes to #{Pyramid::Database.url} from #{options.infile}"

    require 'progress_bar'
    progress = ProgressBar.new(count)

    require 'csv'
    require 'active_support/core_ext'
    CSV.foreach(options.infile) do |row|
      user_id = row[0].to_i
      next if user_id == 0 # must be header row
      listing_id = row[1].to_i if row[1]
      tag_id = row[2].to_i if row[2]
      created_at = DateTime.parse(row[3]).utc
      updated_at = DateTime.parse(row[4]).utc
      begin
        Pyramid::Like.create(user_id: user_id, listing_id: listing_id, tag_id: tag_id, created_at: created_at,
          updated_at: updated_at)
      rescue Pyramid::Like::DuplicateLike
        # achieve idempotence by ignoring duplicate errors
      end
      progress.increment!
    end
  end

  protected
    def cfg(cfg_env = env)
      require 'pyramid/database'
      Pyramid::Database.config(cfg_env)
    end

    def env
      ENV['RACK_ENV']
    end

    def run_command(command)
      say_status :run, command
      IO.popen("#{command} 2>&1") do |f|
        while line = f.gets do
          puts line
        end
      end
    end

    def say_ok(msg)
      say_status :OK, msg, :green
    end

    def say_trace(msg)
      say_status :TRACE, msg, :blue
    end

    def say_error(msg)
      say_status :ERROR, msg, :red
    end
end
