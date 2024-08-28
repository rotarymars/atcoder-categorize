# frozen_string_literal: true

require 'bundler'
require 'selenium-webdriver'
require 'logger'

# Scrape ABC editorial
class ScrapeAbc
  attr_accessor :logger, :from, :to, :driver

  def initialize(from, to, log_dir)
    self.from = from.to_i
    self.to = to.to_i
    init_logger(log_dir)
  end

  def scrape
    log_with("scrape from:#{from} to:#{to}") do
      init_driver
      list = abc_list
    end
  rescue StandardError => e
    logger.error("error:#{e.class.name}:#{e}\n  " + e.backtrace.join("\n  "))
  ensure
    logger.close
  end

  private

  def init_logger(log_dir)
    file =
      File.open(File.join(log_dir, 'scrape_abc.log'),
                File::WRONLY | File::APPEND | File::CREAT)
    self.logger = Logger.new(file)
  end

  def init_driver
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    self.driver = Selenium::WebDriver.for(:chrome, options:)
    driver.manage.timeouts.implicit_wait = 10
  end

  def wait_for_page_to_load(url, options = {})
    options[:timeout] ||= 30

    driver.navigate.to(url)
    wait_until_script(
      'var browserState = document.readyState; return browserState;',
      'complete'
    )
  end

  def wait_until_script(script, result, timeout = 60)
    options = {}
    options[:timeout] = timeout
    wait = Selenium::WebDriver::Wait.new(options)
    wait.until do
      val = driver.execute_script(script)
      val.to_s == result.to_s
    end
  end

  def abc_list
    wait_for_page_to_load('https://kenkoooo.com/atcoder/#/table/')
    wait_until_script(
      "var len = document.querySelectorAll('table')[1].querySelector('tr').querySelectorAll('td').length;return len;",
      9
    )
    tables = driver.find_elements(tag_name: 'table')
    tr_lists = tables[1].find_elements(tag_name: 'tr')
    # driver.save_screenshot('hoge.png')

    abc_list = {}
    tr_lists.each do |tr_elem|
      tds = tr_elem.find_elements(tag_name: 'td')
      name = tds[0].text
      unless name =~ /ABC([0-9]+)/
        logger.warn("skip:#{name}")
        next
      end

      num = Regexp.last_match[1].to_i
      abc_list[num] = []
      8.times do |i|
        atag = tds[i + 1].find_element(tag_name: 'a')
        abc_list[num] << atag.attribute('href')
      rescue Selenium::WebDriver::Error::NoSuchElementError => _e
        next
      end
    end

    abc_list
  end

  def log_with(msg)
    logger.info("start #{msg}")
    yield
    logger.info("end #{msg}")
  end
end

def usage
  puts 'usage: bundle exec ruby scrape_abc.rb FROM_NUM TO_NUM'
end

if ARGV.length != 2
  puts usage
  exit(1)
end

ScrapeAbc.new(ARGV[0], ARGV[1], File.join(__dir__, 'log')).scrape
