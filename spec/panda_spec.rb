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
      "PANDASTREAM_ACCESS_KEY" => "PANDA_ACCESS",
      "PANDASTREAM_SECRET_KEY" => "PANDA_SECRET",
      "PANDASTREAM_CLOUD_ID"   => "PANDA_CLOUD"
    }
    @message = JSON.generate({"id" => "cloud_id", "account_id" => "account_id"})
  end
  
  describe "When taking arguments and config vars" do
    before(:each) do
      panda_gem = mock(PandaGem, :setup_bucket => true)
      PandaGem.stub!(:new).and_return(panda_gem)
    end

    it "should setup bucket arguments" do
      panda = Heroku::Command::Panda.new(["bucket", "key", "secret", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => @config_vars))

      panda_gem = mock(PandaGem, :setup_bucket => true)
      panda_gem.should_receive(:setup_bucket).with(:bucket => "bucket" , :access_key => "key", :secret_key => "secret").and_return(@message)
      PandaGem.should_receive(:new).with(
        "access_key"  =>  "PANDA_ACCESS", 
        "secret_key"  =>  "PANDA_SECRET",
        "cloud_id"    =>  "PANDA_CLOUD"
      ).and_return(panda_gem)

      panda.setup_bucket.should be_true
    end

    it "should take environment vars if key and secret are missing" do
      panda = Heroku::Command::Panda.new(["bucket", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => @config_vars))

      panda_gem = mock(PandaGem, :setup_bucket => true)
      panda_gem.should_receive(:setup_bucket).
        with(:bucket => "bucket" , :access_key => @config_vars["S3_KEY"], :secret_key =>  @config_vars["S3_SECRET"]).and_return(@message)
      PandaGem.should_receive(:new).and_return(panda_gem)

      panda.setup_bucket.should be_true
    end

    it "should abort if all arguments are missing" do
      panda = Heroku::Command::Panda.new(["--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.setup_bucket.should be_false
    end

    it "should abort if key and secret are missing" do
      panda = Heroku::Command::Panda.new(["bucket", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.setup_bucket.should be_false
    end

    it "should abort if PandaStream envrionment vars are missing" do
      panda = Heroku::Command::Panda.new(["bucket", "key", "secret", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.setup_bucket.should be_false
    end
  end
  
  describe "When granting" do
    before(:each) do
      @panda = Heroku::Command::Panda.new(["bucket", "key", "secret", "--app", "myapp"])
      @panda.stub!(:app).and_return("myapp")
      @panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => @config_vars))

      @panda_gem = mock(PandaGem, :setup_bucket => true)
    end

    it "should return successful message" do
      @panda_gem.should_receive(:setup_bucket).and_return(@message)
      PandaGem.should_receive(:new).and_return(@panda_gem)
      @panda.setup_bucket.should == "Successfull:: The bucket permission is setup correctly."
    end
    
    it "should return error message if S3 access is failed" do
      error_message = JSON.generate({"error" => "S3AccessManagerError", "message" => "The bucket is not found"})

      @panda_gem.should_receive(:setup_bucket).and_return(error_message)
      PandaGem.should_receive(:new).and_return(@panda_gem)
      @panda.setup_bucket.should == "Failed:: The bucket is not found"
    end

    it "should return error message if Panda is not accessible" do
      @panda_gem.should_receive(:setup_bucket).and_raise(RestClient::RequestFailed)
      PandaGem.should_receive(:new).and_return(@panda_gem)
      @panda.setup_bucket.should == "Error:: Panda is not accessible. Try again later."
    end
  end
 end