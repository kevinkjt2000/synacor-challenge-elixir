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

  def run_program(program, io \\ IO) do
    zeroed_memory = List.duplicate(0, :math.pow(2, 16) |> trunc())

    initial_memory =
      program
      |> Enum.with_index()
      |> List.foldl(zeroed_memory, fn {word, index}, memory_acc ->
        List.replace_at(memory_acc, index, word)
      end)

    runner(
      %{
        memory: initial_memory,
        pc: 0,
        stack: []
      },
      io
    )
  end

  defp runner(
         %{
           memory: memory,
           pc: pc,
           stack: stack
         } = state,
         io
       ) do
    instr = memory |> Enum.at(pc) |> lookup_instr()

    case instr do
      :eq ->
        a = Enum.at(memory, pc + 1)
        b = Enum.at(memory, pc + 2)
        c = Enum.at(memory, pc + 3)

        updated_memory =
          List.replace_at(
            memory,
            a,
            case b == c do
              true -> 1
              false -> 0
            end
          )

        %{state | :pc => pc + 4, :memory => updated_memory}

      :halt ->
        :halt

      :in ->
        char = io.gets("") |> String.to_charlist() |> Enum.at(0)
        a = Enum.at(memory, pc + 1)
        updated_memory = List.replace_at(memory, a, char)
        %{state | :pc => pc + 2, :memory => updated_memory}

      :noop ->
        %{state | :pc => pc + 1}

      :out ->
        c =
          case Enum.at(memory, pc + 1) do
            val when val > 32767 -> Enum.at(memory, val)
            val -> val
          end

        [c] |> List.to_string() |> io.write()
        %{state | :pc => pc + 2}

      :pop ->
        address = Enum.at(memory, pc + 1)
        [val | popped_stack] = stack
        updated_memory = List.replace_at(memory, address, val)
        %{state | :pc => pc + 2, :stack => popped_stack, :memory => updated_memory}

      :push ->
        val = Enum.at(memory, pc + 1)
        %{state | :pc => pc + 2, :stack => [val | stack]}

      :ret ->
        case stack do
          [] -> :halt
          [val | popped_stack] -> %{state | :pc => val, :stack => popped_stack}
        end

      :set ->
        address = Enum.at(memory, pc + 1)
        val = Enum.at(memory, pc + 2)
        updated_memory = List.replace_at(memory, address, val)
        %{state | :pc => pc + 3, :memory => updated_memory}
    end
    |> case do
      :halt ->
        state

      new_state ->
        runner(new_state, io)
    end
  end

  def main() do
    load_program()
    |> run_program()
  end
end
