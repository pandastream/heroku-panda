begin
  require 'panda'
  PandaGem = Panda 
rescue LoadError
  abort "Error:: Install the Panda gem to use panda commands:\nsudo gem install panda"
end
  
module Heroku::Command
  class Panda < BaseWithApp
    def initialize(*args)
      super
    end
    
    def setup_bucket
      @panda_bucket = args[0]
      @panda_vars = heroku.config_vars(app)
      @panda_key =    args[1] ||  @panda_vars["S3_KEY"]
      @panda_secret = args[2] ||  @panda_vars["S3_SECRET"]
      
      @bucket_config = {
       :bucket => @panda_bucket , :access_key => @panda_key, :secret_key => @panda_secret
      }
      
      @config = {
        "access_key"  =>  @panda_vars["PANDASTREAM_ACCESS_KEY"],
        "secret_key"  =>  @panda_vars["PANDASTREAM_SECRET_KEY"],
        "cloud_id"    =>  @panda_vars["PANDASTREAM_CLOUD_ID"]
      }

      @config["api_host"] = @panda_vars["PANDASTREAM_API_HOST"] if @panda_vars["PANDASTREAM_API_HOST"]
      @config["api_port"] = @panda_vars["PANDASTREAM_API_PORT"] if @panda_vars["PANDASTREAM_API_PORT"]
      
      
      print_error("S3_BUCKET is empty")     if @panda_bucket.to_s.empty?
      print_error("S3_KEY is empty")     if @panda_key.to_s.empty?
      print_error("S3_SECRET is empty")  if @panda_secret.to_s.empty?
      
      @config.each do |key, val|
        print_error("PANDASTREAM_#{key.upcase} Heroku config var is empty") if val.to_s.empty?
      end

      if @will_abort
        print "\n"
        print "Usage:: \n"
        print "\theroku addons:add panda (This will set all PANDASTREAM_* Heroku config vars)\n"
        print "\theroku panda:setup_bucket $S3_BUCKET ($S3_KEY $S3_SECRET)\n"
        return false
      end

      panda = PandaGem.new(@config)
      response = JSON.parse(panda.setup_bucket(@bucket_config))
      
      if response['error']
        print_error(response["message"]) 
        return false
      end
      
    end
    
  private
    def print_error(msg)
      @will_abort = true
      print "Error:: #{msg} \n"
    end
    
  end
end
