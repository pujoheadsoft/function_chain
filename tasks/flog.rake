require 'flog'

desc 'Analyze for code complexity'
task :flog do
  flog = Flog.new(continue: true)
  flog.flog(*FileList['lib/**/*.rb'])
  threshold = 28

  bad_methods = flog.totals.select do |name, score|
    !(/##{flog.no_method}$/ =~ name) && score > threshold
  end
  bad_methods.sort { |a, b| a[1] <=> b[1] }.reverse.each do |name, score|
    printf "%8.1f: %s\n", score, name
  end
  unless bad_methods.empty?
    $stderr.puts "#{bad_methods.size} methods have a complexity > #{threshold}"
  end
end
