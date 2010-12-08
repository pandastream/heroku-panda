require 'rubygems'
require 'panda'

$: << File.dirname(__FILE__) + '/../lib'
require 'heroku'
require 'heroku/command'
require 'heroku/command/panda'

describe Heroku::Command::Panda do
  before do
    @config_vars = {
      "S3_KEY" => 'KEY', "S3_SECRET" => "SECRET",
      "PANDASTREAM_URL" => "http://PANDA_ACCESS:PANDA_SECRET@PANDA_API_HOST:PANDA_API_PORT/PANDA_CLOUD",
    }
    
    @message = JSON.generate({"id" => "cloud_id", "account_id" => "account_id"})
  end
  
  describe "When taking arguments and config vars" do
    before(:each) do
      # panda_gem = mock(PandaGem, :setup_bucket => true)
      PandaGem.stub!(:connect!)
      PandaGem.stub!(:setup_bucket).and_return(true)
    end

    it "should setup bucket arguments" do
      panda = Heroku::Command::Panda.new(["bucket", "key", "secret", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => @config_vars))

      PandaGem.should_receive(:connect!).
        with("http://PANDA_ACCESS:PANDA_SECRET@PANDA_API_HOST:PANDA_API_PORT/PANDA_CLOUD")
      PandaGem.should_receive(:setup_bucket).
        with(:bucket => "bucket" , :access_key => "key", :secret_key => "secret").and_return(@message)

      panda.stub!(:print_message)
      panda.setup_bucket.should be_true
    end

    it "should take environment vars if key and secret are missing" do
      panda = Heroku::Command::Panda.new(["bucket", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => @config_vars))

      PandaGem.should_receive(:setup_bucket).
        with(:bucket => "bucket" , :access_key => @config_vars["S3_KEY"], :secret_key =>  @config_vars["S3_SECRET"]).and_return(@message)

      panda.stub!(:print_message)
      panda.setup_bucket.should be_true
    end

    it "should abort if all arguments are missing" do
      panda = Heroku::Command::Panda.new(["--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.should_receive(:print_message).with(/empty/).at_least(1)
      panda.should_receive(:print_abort_message)
      panda.setup_bucket.should be_false
    end

    it "should abort if key and secret are missing" do
      panda = Heroku::Command::Panda.new(["bucket", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.should_receive(:print_message).with(/empty/).at_least(1)
      panda.should_receive(:print_abort_message)
      panda.setup_bucket.should be_false
    end

    it "should abort if PandaStream envrionment vars are missing" do
      panda = Heroku::Command::Panda.new(["bucket", "key", "secret", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.should_receive(:print_message).with(/empty/).at_least(1)
      panda.should_receive(:print_abort_message)
      panda.setup_bucket.should be_false
    end
  end
  
  describe "When granting" do
    before(:each) do
      @panda = Heroku::Command::Panda.new(["bucket", "key", "secret", "--app", "myapp"])
      @panda.stub!(:app).and_return("myapp")
      @panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => @config_vars))

      PandaGem.stub!(:connect!)
    end

    it "should return successful message" do
      PandaGem.should_receive(:setup_bucket).and_return(@message)
      @panda.should_receive(:print_message).with("Successfull:: The bucket permission is setup correctly.\n")
      @panda.setup_bucket.should be_true
    end
    
    it "should return error message if S3 access is failed" do
      error_message = JSON.generate({"error" => "S3AccessManagerError", "message" => "The bucket is not found"})

      PandaGem.should_receive(:setup_bucket).and_return(error_message)
      @panda.should_receive(:print_message).with("Failed:: The bucket is not found\n")
      @panda.setup_bucket.should be_false
    end

    it "should return error message if Panda is not accessible" do
      PandaGem.should_receive(:setup_bucket).and_raise(RestClient::RequestFailed)
      @panda.should_receive(:print_message).with("Error:: Panda is not accessible. Try again later.\n")
      @panda.setup_bucket.should be_false
    end
  end
 end