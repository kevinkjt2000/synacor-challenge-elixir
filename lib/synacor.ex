defmodule Synacor do
  @instructions %{
    halt: 0,
    set: 1,
    push: 2,
    pop: 3,
    eq: 4,
    gt: 5,
    jmp: 6,
    jt: 7,
    jf: 8,
    add: 9,
    mult: 10,
    mod: 11,
    and: 12,
    or: 13,
    not: 14,
    rmem: 15,
    wmem: 16,
    call: 17,
    ret: 18,
    out: 19,
    in: 20,
    noop: 21
  }
  def lookup_opcode(instr) do
    @instructions[instr]
  end

  def lookup_instr(opcode) do
    @instructions
    |> Enum.find(fn {_key, val} -> val == opcode end)
    |> case do
      {key, _val} -> key
      nil -> :invalid_opcode
    end
  end

  defp load_program(filename \\ "challenge.bin") do
    {:ok, file} = File.open(filename, [:binary, :read])

    file
    |> IO.binread(:all)
    |> :binary.bin_to_list()
  end

  def run_program(
        memory,
        pc \\ 0,
        stack \\ [],
        registers \\ 0..8 |> Map.new(fn reg -> {reg, 0} end)
      ) do
    instr = memory |> Enum.at(pc) |> lookup_instr()

    case instr do
      :halt ->
        :halt

      :noop ->
        {memory, pc + 1, stack, registers}

      :out ->
        register = memory |> Enum.at(pc + 1)
        c = registers |> Map.get(register)
        [c] |> List.to_string() |> IO.write()
        {memory, pc + 2, stack, registers}

      :pop ->
        register = memory |> Enum.at(pc + 1)
        [val | popped_stack] = stack
        new_registers = Map.update!(registers, register, fn _ -> val end)
        {memory, pc + 2, popped_stack, new_registers}

      :push ->
        val = memory |> Enum.at(pc + 1)
        {memory, pc + 2, [val | stack], registers}

      :set ->
        register = memory |> Enum.at(pc + 1)
        val = memory |> Enum.at(pc + 2)
        new_registers = Map.update!(registers, register, fn _ -> val end)
        {memory, pc + 3, stack, new_registers}
    end
    |> case do
      :halt ->
        {memory, pc, stack, registers}

      {memory, pc, stack, registers} ->
        run_program(memory, pc, stack, registers)
    end
  end

  def main() do
    load_program()
    |> run_program()
  end
end
