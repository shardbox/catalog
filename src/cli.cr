require "./formatter"

def show_help(io)
  io.puts "shardbox catalog_tools"
  io.puts "commands:"
  io.puts "  format                       format catalog files"
end

case command = ARGV.shift?
when "format"
  Catalog::Tools.command_format
when nil, "help", "--help"
  show_help(STDOUT)
else
  STDERR.puts "Unknown command #{command}"
  show_help(STDERR)
  exit 1
end
