@main_thread = Thread.current.object_id
puts "main thread: #{@main_thread}"

signals = %w[INT TERM]
signals.each do |signal|
  Signal.trap(signal) do
    next unless Thread.current.object_id == @main_thread
    puts "thread from trap: #{Thread.current.object_id}"
    puts "trapping the signal and sleeping for 5 seconds"
    sleep 5
    puts "done, exiting"
    exit
  end
end

# sleep 10
#`sleep 10`
#t = Thread.new{ `sleep 10` }
t = Thread.new{
  puts "sub thread: #{Thread.current.object_id}"
  puts "start"
  `ls -R /`
  puts "finish"
}
#t = Thread.new{ sleep 10 }
t.join
