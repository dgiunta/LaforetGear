require File.join(File.expand_path(File.dirname(__FILE__)), 'spec_helper')

describe LaforetGear do
  after :each do
    `rm -rf spec/tmp/*.json`
  end

  it "creates the json file if it doesn't exist" do
    @gear = LaforetGear.new("cameras")
    stub_external_requests
    @gear.save
    File.exist?("spec/tmp/cameras.json").should be_true
  end

  it "populates the json file with the contents of to_json" do
    @gear = LaforetGear.new("cameras")
    stub_external_requests
    data = {
      :path => 'cameras',
      :prices => {
        "http://google.com" => "$5.99"
      }
    }
    @gear.should_receive(:prices).and_return({"http://google.com" => "$5.99"})
    @gear.save!
    File.read("spec/tmp/cameras.json").should == data.to_json
  end

  it "updates the file if the file already exists but is out of date" do
    mtime = 6.days.ago
    filename = "spec/tmp/cameras.json"
    data = { "http://google.com" => "$5.99" }

    File.open(filename, 'w+') do |f|
      f << "I'm totally being touched."
    end

    @gear = LaforetGear.new("cameras")
    stub_external_requests

    File.should_receive(:exists?).with(filename).and_return(true)
    File.should_receive(:mtime).with(filename).and_return(mtime)
    @gear.save

    contents = File.read(filename)
    contents.should_not == "I'm totally being touched."
    contents.should =~ /bhphotovideo.com/
    contents.should =~ /\$\d+/
  end

  it "returns the existing file if it is not out of date" do
    mtime = 3.days.ago
    filename = "spec/tmp/cameras.json"
    data = { "http://google.com" => "$5.99" }

    File.open(filename, "w+") do |f|
      f << "I'm not being touched!"
    end

    File.should_receive(:exists?).with(filename).and_return(true)
    File.should_receive(:mtime).with(filename).and_return(mtime)

    @gear = LaforetGear.new("cameras")
    stub_external_requests
    @gear.save

    file = File.open("spec/tmp/cameras.json")
    file.read.should == "I'm not being touched!"
  end

  describe "when first created" do
    before :all do
      @gear = LaforetGear.new("cameras")
      stub_external_requests
    end

    context "#urls" do
      it "returns an array of urls" do
        @gear.urls.should_not be_empty
      end
    end

    context "#prices" do
      before do
        @url = "http://www.bhphotovideo.com/c/product/583953-REG/Canon_2764B003_EOS_5D_Mark_II.html/BI/6768/KBID/7344"
        @gear.stub!(:urls).and_return([@url])
      end

      it "contains a key for each B&H Photo price link" do
        @gear.prices.keys.should include @url
      end

      it "gets the price on each link" do
        @gear.prices[@url].should == "$2,499.00"
      end
    end
  end

  describe "#path" do
    it "parses out the identifier from a url if given" do
      LaforetGear.new("http://blog.vincentlaforet.com/mygear/configurations/").path.should == 'configurations'
      LaforetGear.new("http://blog.vincentlaforet.com/mygear/configurations-1/").path.should == 'configurations-1'
      LaforetGear.new("http://blog.vincentlaforet.com/mygear/configurations/custom-configurations-1/").path.should == 'configurations/custom-configurations-1'
    end
  end

  describe ".sections" do
    it "returns an array of hrefs to all of the gear sections referenced on the main gear page." do
      LaforetGear.sections.should_not be_empty
      LaforetGear.sections.should include("http://blog.vincentlaforet.com/mygear/cameras/")
    end
  end
end

describe Url do
  include Url

  before do
    self.stub!(:open).any_number_of_times.and_return(BH_SOURCE)
  end

  describe '.selector_for' do
    it 'returns ".productInfoArea .value" for bhphoto links' do
      selector_for('http://www.bhphotovideo.com/c/product/583953-REG/Canon_2764B003_EOS_5D_Mark_II.html/BI/6768/KBID/7344').should include '.productInfoArea .value'
    end
  end
end
