require 'rubygems'
require 'bundler/setup'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'active_support'
require 'active_support/core_ext'
require 'yaml'

ENVIRONMENT = ENV['LAFORET_ENV'].to_sym || :development

config = {
  :log_to => "log",
  :save_to => "tmp"
}

if File.exists?('config.yml')
  config_file = YAML.load_file('config.yml')[ENVIRONMENT]
  puts ENVIRONMENT, config_file.inspect
  config.merge!(config_file)
end

CONFIG = config

module Url
  SELECTORS = {
    /bhphotovideo\.com/     => '.productInfoArea .value, #productInfo .value',
    /redrockmicro\.com/     => '#item-price strong',
    /manfrotto\.us/         => '#actionbox h3',
    /glidecam\.com/         => '.banner span',
    /singularsoftware\.com/ => 'p:nth-child(6)',
    /lexar\.com/            => 'span div',
    /usa\.canon\.com/       => '#estimated__retail_price .bold_text',
    /cinevate\.com/         => '.pageHeading:nth-child(2)',
    /pelican-case\.com/     => 'strong',
    /sennheiserusa\.com/    => 'h4',
    /store\.zacuto\.com/    => 'strong span'
  }

  def price_from(url)
    selector = selector_for(url)
    price = Nokogiri::HTML(open(url)).css(selector)[0].content.match(/\$( *)[\d,\.]+/)[0] if selector
    price.gsub(/ /, "") if price
  end

  def selector_for(url)
    key = SELECTORS.keys.find {|site| url =~ site }
    SELECTORS[key]
  end
end

module Debugger
  def debug?
    @debug ||= CONFIG[:debug]
  end

  def sprint msg=""
    message = "#{indent}#{msg}"

    if @logfile
      @logfile.print message
      @logfile.flush
    end

    if debug?
      STDOUT.print message
      STDOUT.flush
    end
  end

  def sputs msg=nil, ignore_indent=false
    message = ignore_indent ? msg : "#{indent}#{msg}"

    if @logfile
      @logfile.puts message
      @logfile.flush
    end

    if debug?
      STDOUT.puts message
      STDOUT.flush
    end
  end

  def indent
    '-' * @indentation_level + " " if @indentation_level && @indentation_level > 0
  end

  def banner msg=""
    sputs "= #{msg}"
  end

  def spacer
    sputs('', true)
  end

  def line
    sputs "-" * 100
  end

  def log_section msg=""
    @indentation_level ||= 0
    sprint "#{msg}... "
    @indentation_level += 1
    yield
    @indentation_level -= 1
    sputs "done."
  end
end

class LaforetGear
  TIMESTAMP = "%m%d%Y-%I%M%p"
  attr_reader :doc, :path, :filename
  include Url
  include Debugger
  extend Debugger

  class << self
    def create!(path, options={})
      new(path, options).save
    end

    def cache_all_prices! options={}
      create_from_sections(options) do |gear|
        gear.save
      end
      create_composite!
    end

    def create_composite!
      files = Dir['tmp/**/*.json']
      output = files.inject({}) do |composite, file|
        data = JSON.parse(File.read(file))
        composite[data["path"]] = data
      end

      File.open("tmp/#{Time.now.strftime(TIMESTAMP)}-composite-output.json", 'w') do |f|
        f << output.to_json
      end
    end

    def create_from_sections options={}
      sections.map do |section|
        gear = new(section, options)
        yield(gear) if block_given?
        gear
      end
    end

    def sections
      doc = Nokogiri::HTML(open("http://blog.vincentlaforet.com/mygear/"))
      doc.css('#sub-nav a').map { |a| a['href'] }
    end
  end

  def initialize(path, options={})
    @path = path =~ /^http.*mygear\/(.*)\/$/ ? $1 : path
    @filename = File.join(CONFIG[:save_to], "#{@path}.json")
    @start_time = Time.now.strftime(TIMESTAMP)
    @logfile = if options[:logfile]
      options[:logfile]
    else
      log_filename = "#{CONFIG[:log_to]}/#{@start_time}.log"
      FileUtils.mkdir_p File.dirname(log_filename)
      File.open log_filename, 'a+'
    end
  end

  def urls
    @doc ||= Nokogiri::HTML(open("http://blog.vincentlaforet.com/mygear/#{@path}/"))
    @urls ||= doc.css("a").map do |a|
      href = a['href']
      href if a.content =~ /B&H|Mfr\. Site/ && selector_for(href)
    end.compact.sort
  end

  def prices
    @prices ||= fetch_prices!
  end

  def fetch_prices!
    spacer
    banner "Prices:"
    urls.inject({}) do |prices, url|
      log_section(url) do
        prices[url] = price_from(url) rescue nil
        sprint prices[url] if debug?
      end
      prices
    end
  end

  def total
    prices.values.compact.map {|v| v.gsub(/^\$/, '').to_f }.inject(0) {|sum, i| sum += i }
  end

  def to_hash
    {
      :prices => prices,
      :path => path
    }
  end

  def to_json
    to_hash.to_json
  end

  def save!
    log_section("Ensuring #{File.dirname(filename)} exists") do
      FileUtils.mkdir_p(File.dirname(filename))
    end

    log_section("Saving #{filename}") do
      File.open filename, 'w+' do |f|
        f << to_json
      end
    end

    line
  end

  def save
    save! if saveable?
  end

  private

  def saveable?
    !File.exists?(filename) || File.mtime(filename) < 5.days.ago
  end
end
