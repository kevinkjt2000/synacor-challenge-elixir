defmodule SynacorTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  doctest Synacor
  import Synacor

  @moduletag timeout: 1000

  @reg0 32768
  @reg1 32769
  # @reg2 32770
  # @reg3 32771
  # @reg4 32772
  # @reg5 32773
  # @reg6 32774
  # @reg7 32775

  test "ret jumps to top of stack" do
    program = [
      lookup_opcode(:push),
      1000,
      lookup_opcode(:ret)
    ]

    assert %{pc: 1000} = run_program(program)
  end

  test "ret halts when stack is empty" do
    program = [lookup_opcode(:ret)]
    assert %{} = run_program(program)
  end

  test "numbers are comparable" do
    program = [
      lookup_opcode(:set),
      @reg0,
      42,
      lookup_opcode(:set),
      @reg1,
      800,
      lookup_opcode(:eq),
      1000,
      @reg0,
      @reg1,
      lookup_opcode(:eq),
      2000,
      @reg0,
      @reg0
    ]

    assert %{memory: memory} = run_program(program)
    assert Enum.at(memory, 1000) == 0
    assert Enum.at(memory, 2000) == 1
  end

  test "empty program halts immediately" do
    assert %{} = run_program([])
  end

  test "registers are updated after set instructions" do
    program = [
      lookup_opcode(:set),
      @reg0,
      42,
      lookup_opcode(:set),
      @reg1,
      800
    ]

    assert %{memory: memory} = run_program(program)
    assert Enum.at(memory, @reg0) == 42
    assert Enum.at(memory, @reg1) == 800
  end

  test "can output characters to the screen" do
    program = [lookup_opcode(:set), @reg0, ?h, lookup_opcode(:out), @reg0]

    assert capture_io(fn -> run_program(program) end) == "h"
  end

  test "noop does nothing" do
    program = [lookup_opcode(:noop), lookup_opcode(:noop)]
    assert %{pc: pc} = run_program(program)
    assert pc == 2
  end

  test "can push/pop from the stack" do
    program = [lookup_opcode(:push), 42, lookup_opcode(:pop), @reg0, lookup_opcode(:halt)]
    assert %{memory: memory, stack: stack} = run_program(program)

    assert stack == []
    assert Enum.at(memory, @reg0) == 42
  end
end
