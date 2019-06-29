defmodule SynacorTest do
  use ExUnit.Case
  doctest Synacor
  import Synacor

  test "recognizes suggested opcodes" do
    assert run_program([lookup_opcode(:out), ?h, lookup_opcode(:halt)]) == [
             "out(a)",
             "invalid opcode",
             "halt()"
           ]
  end
end
