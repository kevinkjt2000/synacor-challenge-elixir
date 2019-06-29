defmodule SynacorTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  doctest Synacor
  import Synacor

  test "recognizes suggested opcodes" do
    assert capture_io(fn ->
             run_program([lookup_opcode(:out), ?h, lookup_opcode(:halt)])
           end) == "h"
  end
end
