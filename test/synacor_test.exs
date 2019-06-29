defmodule SynacorTest do
  use ExUnit.Case
  doctest Synacor

  test "recognizes suggested opcodes" do
    assert Synacor.run_program([21, 19, 0]) == ["noop()", "out(a)", "halt()"]
  end
end
