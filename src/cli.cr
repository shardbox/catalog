require "./formatter"
require "./awesome_list"

def show_help(io)
  io.puts "shardbox catalog_tools"
  io.puts "commands:"
  io.puts "  format                       format catalog files"
end

case command = ARGV.shift?
when "format"
  if Catalog::Tools.command_format
    exit 0
  else
    exit 1
  end
when "awesome_list"
  Catalog::Tools.command_awesome_list(ARGV)
when nil, "help", "--help"
  show_help(STDOUT)
else
  STDERR.puts "Unknown command #{command}"
  show_help(STDERR)
  exit 1
end
