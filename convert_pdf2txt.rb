# frozen_string_literal: true

require 'fileutils'

# ABC 001 から 174 までの 解説 pdf から 各問題の解説だけを抜き出す。

# convert pdf to html
def convert(idx, problem)
  dir = File.join('out', format('%03d', idx))

  path = File.join(dir, "#{problem}.pdf")
  work_path = File.join(dir, "#{problem}.tmp")
  out_path = File.join(dir, "#{problem}.txt")

  `pdftotext #{path} #{work_path}`

  start = false
  File.open(out_path, 'w') do |f|
    File.foreach(work_path) do |line|
      line.gsub!(/\x0c/, '')

      if line =~ /^((#{problem}.*問題.*)|(問題.*#{problem})|(#{problem} *(:|\.).*)|(#{problem}[ 　]*(-|–).*))/
        start = true
        next
      elsif line =~ /^(((A|B|C|D|E|F|G|H|Ex).*問題.*)|(問題.*(A|B|C|D|E|F|G|H|Ex)|((A|B|C|D|E|F|G|H|Ex) *(:|\.).*))|((A|B|C|D|E|F|G|H|Ex)[ 　]*(-|–).*))/
        start = false
      end

      f.puts line if start
    end
  end

  FileUtils.rm(work_path)
end

(1..174).each do |i|
  Dir.glob(File.join('out', format('%03d', i), '*.pdf')) do |f|
    convert(i, File.basename(f, '.*'))
  end
end
