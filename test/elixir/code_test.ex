Code.require "os"

object CodeTest
  proto ExUnit::Case

  def paths_test
    Code.unshift_path "test/elixir/fixtures"
    true = Code.paths.include? File.expand_path("test/elixir/fixtures")
  after
    Code.delete_path "test/elixir/fixtures"
  end

  def require_test
    self.assert_raise { 'enoent, "code_sample" }, do
      Code.require "code_sample"
    end

    Code.unshift_path "test/elixir/fixtures"
    true  = Code.require "code_sample"
    false = Code.require "code_sample"
    Code.loaded.include? File.expand_path("test/elixir/fixtures/code_sample.ex")
  after
    Code.delete_path "test/elixir/fixtures"
  end

  def code_init_test
    "3\n"                   = OS.cmd("bin/elixir -e \"IO.puts 1 + 2\"")
    "5\n3\n"                = OS.cmd("bin/elixir -f \"IO.puts 1 + 2\" -e \"IO.puts 3 + 2\"")
    "3\n5\n1\n"             = OS.cmd("bin/elixir -f \"IO.puts 1\" test/elixir/fixtures/init_sample.ex -e \"IO.puts 3 + 2\"")
    "[\"1\",\"2\",\"3\"]\n" = OS.cmd("bin/elixir -e \"IO.puts Code.argv\" -- 1 2 3")
  end
end