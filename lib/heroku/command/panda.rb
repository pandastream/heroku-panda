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
      
      panda_url = @panda_vars["PANDASTREAM_URL"]

      print_error("S3_BUCKET is empty")   if @panda_bucket.to_s.empty?
      print_error("S3_KEY is empty")      if @panda_key.to_s.empty?
      print_error("S3_SECRET is empty")   if @panda_secret.to_s.empty?
      
      print_error("PANDASTREAM_URL var is empty") if panda_url.to_s.empty?
      

      if @will_abort
        print_abort_message
        return false
      end

      PandaGem.configure(panda_url)
      begin
        result = PandaGem.setup_bucket(@bucket_config)
        result = JSON.parse(result) if result.is_a?(String)
      rescue Panda::ServiceNotAvailable
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
