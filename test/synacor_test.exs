defmodule SynacorTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  doctest Synacor
  import Synacor

  test "can output characters to the screen" do
    assert capture_io(fn ->
             run_program([lookup_opcode(:out), ?h, lookup_opcode(:halt)])
           end) == "h"
  end

  test "noop does nothing" do
    program = [lookup_opcode(:noop), lookup_opcode(:noop), lookup_opcode(:halt)]
    assert {_memory, pc, _stack, _registers} = run_program(program)
    assert pc == 2
  end

  test "can push/pop from the stack" do
    assert {_memory, _pc, stack, registers} =
             run_program([lookup_opcode(:push), 42, lookup_opcode(:pop), 0, lookup_opcode(:halt)])

    assert stack == []
    assert registers[0] == 42
  end
end
