# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'mechanize'
require 'retryable'
require 'uri'

# Scrape ABC editorial
class ScrapeAbc
  attr_accessor :logger, :from, :to, :agent, :out_dir

  def initialize(from, to, log_dir)
    self.from = from.to_i
    self.to = to.to_i
    self.out_dir = File.join(__dir__, 'out')
    init_logger(log_dir)
  end

  def scrape
    log_with("scrape from:#{from} to:#{to}") do
      init_agent
      (from..to).each do |i|
        analyze(i)
      end
    end
  rescue StandardError => e
    logger.error("error:#{e.class.name}:#{e}\n  " + e.backtrace.join("\n  "))
  ensure
    logger.close
  end

  private

  def init_logger(log_dir)
    file =
      File.open(File.join(log_dir, 'scrape_abc.log'), 'a')
    file.sync = true
    self.logger = Logger.new(file)
  end

  def init_agent
    self.agent = Mechanize.new
    agent.request_headers = {
      'accept-language' => 'ja,en-US;q=0.8,en;q=0.6,zh-CN;q=0.4,zh;q=0.2'
    }
  end

  def log_with(msg)
    logger.info("start #{msg}")
    yield
    logger.info("end #{msg}")
  end

  def analyze(i)
    base_dir = File.join(out_dir, '%03d' % i)
    FileUtils.mkdir_p(base_dir)
    log_with("scrapce #{i}") do
      editorial_url = "https://atcoder.jp/contests/abc#{'%03d' % i}/editorial"
      editorial_page = get_page(editorial_url)
      sleep(3)
      %w[A B C D E F G Ex].each do |problem|
        analyze_problem(problem, editorial_page, base_dir)
      end
    end
  end

  def analyze_problem(problem, editorial_page, base_dir)
    h3 = editorial_page.at("h3:contains(\"#{problem} -\")")
    return unless h3

    ul = h3.next.next
    link = ul.at('a')
    link_url = nil
    link_url = link.attributes['href'].text if link&.text == '解説'

    unless link_url
      ul = editorial_page.search('h3:contains("コンテスト全体の解説") ~ ul')
      link = ul.at('a')
      link_url = link.attributes['href'].text if link
    end

    if link_url
      if link_url =~ /\.pdf/
        path = File.join(base_dir, "#{problem}.pdf")
        if File.exist?(path)
          # logger.info("skip #{path} because file exists")
          # return
          FileUtils.rm(path)
        end

        if link_url =~ %r{/jump}
          url = URI.parse(link_url)
          query = URI.decode_www_form(url.query.to_s).to_h

          sleep(3)
          file = get_page(query['url'])
        else
          file = get_page(link_url)
        end
        file.save_as(path)
      else
        path = File.join(base_dir, "#{problem}.html")
        if File.exist?(path)
          logger.info("skip #{path} because file exists")
          return
        end
        page = get_page(link_url)
        File.open(path, 'w') do |f|
          f.write(page.body)
        end
      end
      sleep(3)
    else
      logger.warn("can't get editorial url:#{editorial_page.title} #{problem}")
    end
  end

  def get_page(url)
    log_method = lambda do |retries, exception|
      logger.warn("[Attempt ##{retries}] Retrying because [#{exception.class} - #{exception.message}]:]n  " + exception.backtrace.join("\n  "))
    end
    Retryable.retryable(log_method:, matching: /403/, tries: 5, sleep: 120) do
      agent.get(url)
    end
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
