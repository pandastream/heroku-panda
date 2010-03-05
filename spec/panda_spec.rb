require 'rubygems'
require 'panda'

$: << File.dirname(__FILE__) + '/../lib'
require 'heroku'
require 'heroku/command'
require 'heroku/command/panda'

describe Heroku::Command::Panda do
  before do
    panda_gem = mock(PandaGem, :setup_bucket => true)
    PandaGem.stub!(:new).and_return(panda_gem)
    @config_vars = {
      "S3_KEY" => 'KEY', "S3_SECRET" => "SECRET",
      "PANDASTREAM_ACCESS_KEY" => "PANDA_ACCESS",
      "PANDASTREAM_SECRET_KEY" => "PANDA_SECRET",
      "PANDASTREAM_CLOUD_ID"   => "PANDA_CLOUD"
    }
  end
  
  describe "When taking arguments and config vars" do
    it "should setup bucket arguments" do
      panda = Heroku::Command::Panda.new(["bucket", "key", "secret", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => @config_vars))

      panda_gem = mock(PandaGem, :setup_bucket => true)
      panda_gem.should_receive(:setup_bucket).with(:bucket => "bucket" , :access_key => "key", :secret_key => "secret")
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
        with(:bucket => "bucket" , :access_key => @config_vars["S3_KEY"], :secret_key =>  @config_vars["S3_SECRET"])
      PandaGem.should_receive(:new).and_return(panda_gem)

      panda.setup_bucket.should be_true
    end

    it "should raise error if all arguments are missing" do
      panda = Heroku::Command::Panda.new(["--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.setup_bucket.should be_false
    end

    it "should raise error if key and secret are missing" do
      panda = Heroku::Command::Panda.new(["bucket", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.setup_bucket.should be_false
    end

    it "should raise error if PandaStream envrionment vars are missing" do
      panda = Heroku::Command::Panda.new(["bucket", "key", "secret", "--app", "myapp"])
      panda.stub!(:app).and_return("myapp")
      panda.stub!(:heroku).and_return(mock('heroku client', :config_vars => {}))
      panda.setup_bucket.should be_false
    end
  end
  
 end