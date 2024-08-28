require 'natto'
require 'set'
require 'gdbm'

# DIC_DIR = '/opt/homebrew/lib/mecab/dic/mecab-ipadic-neologd'
DIC_DIR = ' /usr/lib/x86_64-linux-gnu/mecab/dic/mecab-ipadic-neologd'

def link_url(path)
  link_path =
    File.join(File.dirname(path),
              "#{File.basename(path, '.*')}.link")
  File.open(link_path, 'r') do |f|
    url = f.read.chomp!
    url = "https://atcoder.jp#{url}" if url =~ %r{^/}
    return url
  end

  nil
end

def analyze(file, path, gdbm, ignore_list)
  # nm = Natto::MeCab.new("-F%m\t%f[0]\n -d#{DIC_DIR}")
  nm = Natto::MeCab.new("-F %m\\t%f[0]\\t%f[1] -d #{DIC_DIR}")
  s = Set.new

  File.open(path, 'r') do |f|
    nm.enum_parse(f.read).each do |n|
      val = n.feature.split("\t")
      next unless val[1]&.include?('名詞')
      next if ignore_list.include?(val[0])
      next if val[0] =~ /^-?[a-zA-Z0-9]$/
      next if val[0] =~ /^-?[0-9]+$/
      next if val[0] =~ /^-?[０-９]+$/

      s.add(val[0])
      gdbm[val[0]] ||= '0'
      gdbm[val[0]] = (gdbm[val[0]].to_i + 1).to_s
    end
  end

  contest = File.basename(File.dirname(path))
  problem = File.basename(path, '.*')
  file.print("abc,#{contest},#{problem},#{link_url(path)},")

  file.puts(s.join(','))
end

ignore_list = []

File.foreach('ignore_words.txt') do |line|
  next if line.empty?

  ignore_list << line.chomp
end

File.open('analyze.csv', 'w') do |file|
  GDBM.open('word.db', 0o666, GDBM::NEWDB | GDBM::WRCREAT) do |gdbm|
    Dir.glob(File.join('out', '**', '*.txt')).sort.each do |path|
      analyze(file, path, gdbm, ignore_list)
    end
  end
end
