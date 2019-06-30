defmodule MockIO do
  def gets(_prompt) do
    "m\n"
  end

  def write(mesg) do
    IO.write(mesg)
  end
end

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

  describe "comparisons" do
    test "numbers are eq comparable" do
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

    test "numbers are gt comparable" do
      program = [
        lookup_opcode(:set),
        @reg0,
        42,
        lookup_opcode(:set),
        @reg1,
        800,
        lookup_opcode(:gt),
        1000,
        @reg0,
        @reg1,
        lookup_opcode(:gt),
        2000,
        @reg0,
        @reg0,
        lookup_opcode(:gt),
        3000,
        @reg1,
        @reg0
      ]

      assert %{memory: memory} = run_program(program)
      assert Enum.at(memory, 1000) == 0
      assert Enum.at(memory, 2000) == 0
      assert Enum.at(memory, 3000) == 1
    end
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

  describe "jumps" do
    test "jmp sets pc appropriately" do
      program = [lookup_opcode(:jmp), 1000]

      assert %{pc: 1000} = run_program(program)
    end

    test "jt sets pc appropriately" do
      jump_prog = [lookup_opcode(:set), @reg0, 5, lookup_opcode(:jt), @reg0, 1000]
      no_jump_prog = [lookup_opcode(:set), @reg0, 0, lookup_opcode(:jt), @reg0, 1000]
      assert %{pc: 1000} = run_program(jump_prog)
      assert %{pc: 6} = run_program(no_jump_prog)
    end

    test "jf sets pc appropriately" do
      jump_prog = [lookup_opcode(:set), @reg0, 0, lookup_opcode(:jf), @reg0, 1000]
      no_jump_prog = [lookup_opcode(:set), @reg0, 5, lookup_opcode(:jf), @reg0, 1000]
      assert %{pc: 1000} = run_program(jump_prog)
      assert %{pc: 6} = run_program(no_jump_prog)
    end
  end

  describe "i/o" do
    test "in instruction can read from user" do
      program = [
        lookup_opcode(:in),
        1000
      ]

      assert %{memory: memory} = run_program(program, MockIO)
      assert Enum.at(memory, 1000) == ?m
    end

    test "can output characters to the screen" do
      program = [lookup_opcode(:set), @reg0, ?h, lookup_opcode(:out), @reg0]

      assert capture_io(fn -> run_program(program) end) == "h"
    end
  end

  describe "stack manipulation" do
    test "ret halts when stack is empty" do
      program = [lookup_opcode(:ret)]
      assert %{} = run_program(program)
    end

    test "ret jumps to top of stack" do
      program = [
        lookup_opcode(:push),
        1000,
        lookup_opcode(:ret)
      ]

      assert %{pc: 1000} = run_program(program)
    end

    test "can push/pop from the stack" do
      program = [lookup_opcode(:push), 42, lookup_opcode(:pop), @reg0]
      assert %{memory: memory, stack: stack} = run_program(program)

      assert stack == []
      assert Enum.at(memory, @reg0) == 42
    end

    test "call writes next pc to the top of stack" do
      program = [lookup_opcode(:call), 1000]
      assert %{pc: 1000, stack: [2]} = run_program(program)
    end
  end

  describe "idle programs" do
    test "noop does nothing" do
      program = [lookup_opcode(:noop), lookup_opcode(:noop)]
      assert %{pc: pc} = run_program(program)
      assert pc == 2
    end

    test "empty program halts immediately" do
      assert %{} = run_program([])
    end
  end
end
