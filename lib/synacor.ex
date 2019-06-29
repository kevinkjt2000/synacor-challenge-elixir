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

  defp load_program() do
    filename = "challenge.bin"
    {:ok, file} = File.open(filename, [:binary, :read])

    file
    |> IO.binread(:all)
    |> :binary.bin_to_list()
  end

  def run_program(program) do
    program
    |> Enum.map(&lookup_instr(&1))
  end
end
