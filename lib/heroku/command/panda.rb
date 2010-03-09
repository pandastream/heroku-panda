begin
  require 'panda'
  PandaGem = Panda 
rescue LoadError
  abort "Error:: Install the Panda gem to use panda commands:\nsudo gem install panda"
end

begin
  require 'json'
rescue LoadError
  abort "Error:: Install the json gem to use panda commands:\nsudo gem install json"
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
        print_abort_message
        return false
      end

      panda = PandaGem.new(@config)
      begin
        result = JSON.parse(panda.setup_bucket(@bucket_config))
      rescue RestClient::RequestFailed
        print_message "Error:: Panda is not accessible. Try again later.\n"
        return false
      end
      
      if result["id"]
        print_message "Successfull:: The bucket permission is setup correctly.\n"
        return true
      elsif result["error"]
        print_message "Failed:: #{result["message"]}\n"
        return false
      else  
        raise "Something is wrong"
      end
    end
    
  private
    def print_message(msg)
      print msg
    end
    
    def print_abort_message
      print "\n"
      print "Operation aborted\n"
      print "Usage:: \n"
      print "\theroku addons:add panda (This will set all PANDASTREAM_* Heroku config vars)\n"
      print "\theroku panda:setup_bucket $S3_BUCKET ($S3_KEY $S3_SECRET)\n"
    end

    def print_error(msg)
      @will_abort = true
      print_message "Error:: #{msg} \n"
    end
    
    
  end
end
