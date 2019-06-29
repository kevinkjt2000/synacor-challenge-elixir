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
    |> Enum.find(fn {key, val} -> val == opcode end)
    |> elem(0)
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
    |> Enum.map(fn
      0 ->
        "halt()"

      1 ->
        "set(reg_a, b)"

      2 ->
        "push(a)"

      3 ->
        "pop(a)"

      4 ->
        "eq(a, b, c)"

      5 ->
        "gt(a, b, c)"

      6 ->
        "jmp(a)"

      7 ->
        "jt(a, b)"

      8 ->
        "jf(a, b)"

      9 ->
        "add(a, b, c)"

      10 ->
        "mult(a, b, c)"

      11 ->
        "mod(a, b, c)"

      12 ->
        "and(a, b, c)"

      13 ->
        "or(a, b, c)"

      14 ->
        "not(a, b)"

      15 ->
        "rmem(a, mem_b)"

      16 ->
        "wmem(mem_a, b)"

      17 ->
        "call(a)"

      18 ->
        "ret()"

      19 ->
        "out(a)"

      20 ->
        "in(a)"

      21 ->
        "noop()"

      _ ->
        "invalid opcode"
    end)
  end
end
