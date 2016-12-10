#!/usr/bin/env ruby

begin
  require 'rails_best_practices'
  require 'tempfile'
  require 'pathname'
  require 'json'
rescue LoadError
  puts "Install rails_best_practices!\ngem install rails_best_practices"
  exit 1
end

def log(msg)
  require 'logger'
  logger = Logger.new('/tmp/rails_best_practices_bundle.log')
  logger.info msg
end

def offences(file)
  io = Tempfile.new('rails_best_practices')
  options = {}
  options['format'] = 'json'
  options['output-file'] = io.path
  options['silent'] = true
  analyzer = RailsBestPractices::Analyzer.new(Pathname.new(file).dirname, options)
  analyzer.analyze
  analyzer.output
  JSON.parse(io.read)
end

def messages(offences)
  messages = {
    message: {}
  }
  offences.each do |offence|
    if ENV['TM_FILEPATH'] == offence['filename']
      severity = :message
      line = offence["line_number"].to_i
      message = messages[severity][line] ||= []
      message << offence["message"].gsub('`', "'").gsub(',', ' ')
    end
  end
  messages
end

def command(messages)
  icons = {
    message: "#{ENV['TM_BUNDLE_SUPPORT']}/police.png".inspect
  }
  args = []

  messages.each do |severity, messages|
    args << ["--clear-mark=#{icons[severity]}"]
    messages.each do |line, message|
      args << "--set-mark=#{icons[severity]}:#{message.uniq.join('. ').inspect}"
      args << "--line=#{line}"
    end
  end

  args << ENV['TM_FILEPATH'].inspect
  "#{ENV['TM_MATE']} #{args.join(' ')}"
end

cmd = command(messages(offences(ENV['TM_FILEPATH'])))

# log cmd
exec cmd