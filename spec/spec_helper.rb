require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)

require 'open-uri'
require 'ruby-debug'
require 'rspec'

ENV["LAFORET_ENV"] = 'test'
require File.join(File.expand_path(File.dirname(__FILE__)), '../laforet_gear.rb')

if ENV["REAL_REQUESTS"]
  print "Getting real content for non-stubbed requests... "
  GEAR_SOURCE = open("http://blog.vincentlaforet.com/mygear/cameras/").read
  BH_SOURCE = open("http://www.bhphotovideo.com/c/product/583953-REG/Canon_2764B003_EOS_5D_Mark_II.html").read
  MAIN_PAGE_SOURCE = open("http://blog.vincentlaforet.com/mygear/").read
  puts "done."
else
  print "Getting fixture content for stubbed requests... "
  GEAR_SOURCE = File.read(File.expand_path("./spec/fixtures/laforet_gear-cameras.html"))
  BH_SOURCE = File.read(File.expand_path("./spec/fixtures/bhphoto-5dmkII.html"))
  MAIN_PAGE_SOURCE = File.read(File.expand_path("./spec/fixtures/main_page.html"))
  puts "done."
end

def stub_external_requests
  Url.stub!(:open).any_number_of_times.and_return(BH_SOURCE)
  LaforetGear.stub!(:open).with("http://blog.vincentlaforet.com/mygear/").and_return(MAIN_PAGE_SOURCE)
  return unless @gear
  @gear.stub!(:open).any_number_of_times.and_return(BH_SOURCE)
  @gear.stub!(:open).with("http://blog.vincentlaforet.com/mygear/cameras/").any_number_of_times.and_return(GEAR_SOURCE)
end
