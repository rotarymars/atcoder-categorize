# What is this?

This is a program to scrape AtCoder ABC(AtCoder Beginner Contests) problems editorials.

# How to run

## scrape

```bash
bundle install
bundle exec ruby scrape_abc.rb 1 340
```

scrape_abc.rb is received two arguments.
The first argument is the first problem number to scrape an editorial.
The send argument is to last problem number to scrape an editorial.

## convert html and pdf

```bash
bundle exec ruby convert_pdf2txt.rb
bundle exec ruby convert_html2txt.rb
```

## generate analyze.csv

```bash
bundle exec ruby analyze.rb
bundle exec ruby analyze_words.rb
```
