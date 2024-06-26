require 'yaml'

module Tasque
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Configuration.new
    yield(config) if block_given?
    self.database_connection
    return self.config
  end
  
  def self.database_connection()
    raise 'No configuration. Use Tasque.configure' if self.config.nil?
    @database ||= begin
      if !defined?(Rails) && !ActiveRecord::Base.connected?
        ActiveRecord::Base.logger = self.config.logger
        db = self.config.database[self.config.environment.to_s]
        db = self.config.database if db.nil?
        ActiveRecord::Base.establish_connection(db)
        ActiveRecord::Base.connection
      end
      ActiveRecord::Base
    end
  end
  
  def self.root
    defined?(TASQUE_ROOT) ? TASQUE_ROOT : Dir.pwd
  end

  class Configuration
    attr_accessor :database
    attr_accessor :database_file
    attr_accessor :environment
    attr_accessor :logger
    attr_accessor :check_interval
    attr_accessor :progress_interval
    attr_accessor :minimum_priority
    attr_accessor :worker
    attr_accessor :heartbeat
    attr_accessor :heartbeat_interval
    attr_accessor :heartbeat_payload
    attr_accessor :notify
    attr_accessor :use_mutex
    attr_accessor :mutex_name
    attr_accessor :mutex_options

    def initialize
      self.environment = :development
      self.database_file = ::File.expand_path('config/database.yml', Tasque.root)
      self.check_interval = 10 # seconds
      self.worker = "default"
      self.progress_interval = 5 # seconds
      self.heartbeat = false
      self.heartbeat_interval = 10 # seconds
      self.heartbeat_payload = {}
      self.notify = false
      self.use_mutex = false
      self.mutex_name = 'tasque_task_pickup'
      self.mutex_options = {}
    end
    
    def database_file=(path)
      if File.exists?(path)
        @database = YAML.load(File.read(path), aliases: true) || {}
        @database_file = path
      end
    end
    
  end
end
