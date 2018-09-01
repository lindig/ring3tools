#! /usr/bin/env ruby
#
#  Report code size by OCaml module in a native binary
#
require 'set'
require 'getoptlong'

class OCamlModule
  include Comparable

  attr_reader :name, :start, :stop
  
  def initialize(name, start) 
    @name  = name
    @start = start
    @stop  = nil
  end

  def <=>(other)
    return self.name <=> other.name
  end

  def to_s
    @name
  end

  def size 
    (@stop-@start).to_f/1024.0
  end

  def stop(addr)
    @stop = addr
  end
end

class OCamlBinary

  @@start = %r{(^[a-f0-9]{16}) ([a-zA-Z]) _?caml(.*)__code_begin$}
  @@stop  = %r{(^[a-f0-9]{16}) ([a-zA-Z]) _?caml(.*)__code_end$}

  attr_reader :name, :modules

  def initialize(name)
    @name    = name
    @modules = Hash.new
    self.read
  end

  def to_s
    @name
  end

  def keys
    @modules.keys
  end

  def read
    cmd = ["/usr/bin/nm", "-n", @name]
    IO.popen(cmd) do |io|
      io.each do |line|

        match = @@start.match(line)
        if match then
          name  = match[3]
          addr  = match[1].to_i(16)
          @modules[name] = OCamlModule.new(name, addr)
        end

        match = @@stop.match(line)
        if match then
          name  = match[3]
          addr  = match[1].to_i(16)
          @modules[name].stop(addr)
        end
      end
    end
  end

  def dump
    @modules.each do |name, m|
	    printf "%6.1f %s\n", m.size, name
    end
  end
end

def report1(left)
  left  = OCamlBinary.new(left)
  puts "# modules in #{left.name} (size in Kb)"
  left.modules.sort.each do |_,m|
    printf("%-50s %6.1f\n", m.name, m.size)
  end
end

def report2(left,right)
  left   = OCamlBinary.new(left)
  right  = OCamlBinary.new(right)

  l = Set.new(left.modules.keys)
  r = Set.new(right.modules.keys)

  puts "# modules in #{left.name} #{right.name} (size in Kb)"

  left_total = 0
  right_total = 0
  (l & r).sort.each do |m|
    printf("%-50s %6.1f %6.1f\n", m, left.modules[m].size, right.modules[m].size)
    left_total += left.modules[m].size
    right_total += right.modules[m].size
  end
  printf("# totals: %6.1f %6.1f\n",left_total,right_total)

  left_total = 0
  puts
  puts "# modules only in #{left.name} (size in Kb)" 
  (l - r).sort.each do |m|
    printf("%-50s %6.1f\n", m, left.modules[m].size)
    left_total += left.modules[m].size
  end
  printf("# total: %6.1f\n",left_total)

  right_total = 0
  puts
  puts "# modules only in #{right.name} (size in Kb)" 
  (r - l).sort.each do |m|
    printf("%-50s %6.1f\n", m, right.modules[m].size)
    right_total += right.modules[m].size
  end
  printf("# total: %6.1f\n",right_total)
end

opts = GetoptLong.new(
  [ '--help'        , '-h', GetoptLong::NO_ARGUMENT ],
)

opts.each do |opt, arg|
  case opt
  when '--help'
    puts <<~EOF
    #{$0} ocaml.exe [ocaml.exe]
    
    Report the code size per OCaml module found in the binary
    provided as argument. When two binaries are provided, report
    modules found in both and only either of the binaries.
    EOF

    exit 0
  else
    raise ArgumentError, "#{opt} not recognized"
  end
end

case ARGV.length
when 0
  STDERR.puts "At least one binary needs to be provided"
  exit 1
when 1
  file = ARGV[0]
  if not File.exists?(file) then
    STDERR.puts "Does not exist: #{file}"
    exit 1
  end
  report1(ARGV[0])
when 2
  left = ARGV[0]
  right = ARGV[1]
 
  if not File.exists?(left) then
    STDERR.puts "File does not exist: #{left}"
    exit 1
  end
  if not File.exists?(right) then
    STDERR.puts "File does not exist: #{right}"
    exit 1
  end

  report2(left, right)
else 
  STDERR.puts "More than two binaries provided."
  exit 1
end

