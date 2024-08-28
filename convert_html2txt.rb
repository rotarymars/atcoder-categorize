# frozen_string_literal: true

require 'fileutils'
require 'nokogiri'

def convert(path)
  dir = File.dirname(path)
  bname = File.basename(path, '.*')
  out_path = File.join(dir, "#{bname}.txt")

  File.open(out_path, 'w') do |f|
    File.open(path, 'r') do |hf|
      doc = Nokogiri::HTML(hf.read)
      puts path
      contents = doc.at('body').search('#main-container .col-sm-12')[1]
      contents.search('pre').map(&:remove)
      f.puts contents.text
    end
  end
end

Dir.glob(File.join('out', '**', '*.html')) do |f|
  convert(f)
end
