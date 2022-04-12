# require 'posix-spawn'
require 'terrapin'
require 'rufus-scheduler'

schedule = Rufus::Scheduler.singleton
schedule.pause

schedule.every '1s' do
  puts "hello"
  Terrapin::CommandLine.new('sleep 5').run
  # `sleep 50`
end

signals = %w[INT TERM]
signals.each do |signal|
  Signal.trap(signal) do
    schedule.shutdown(wait: 100)
    exit
  end
end

schedule.resume
schedule.join

sleep 3
Rufus::Scheduler.singleton.shutdown(wait: 100)
