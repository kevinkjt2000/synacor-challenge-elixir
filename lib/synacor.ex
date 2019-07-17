defmodule Synacor do
  use Bitwise

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
    Map.get(@instructions, instr)
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
    |> Enum.chunk_every(2)
    |> Enum.map(fn [a, b] ->
      <<word::16>> = <<b::8, a::8>>
      word
    end)
  end

  def run_program(program, io \\ IO) do
    memory = :ets.new(:program_memory, [:set, :protected])

    program
    |> Enum.with_index()
    |> Enum.map(fn {val, key} -> :ets.insert(memory, {key, val}) end)

    initial_state = %{
      input_buffer: [],
      io: io,
      memory: memory,
      pc: 0,
      running: true,
      stack: []
    }

    Stream.iterate(initial_state, &runner/1)
    |> Stream.drop_while(fn %{running: running} -> running end)
    |> Enum.at(0)
  end

  defp runner(
         %{
           input_buffer: input_buffer,
           io: io,
           memory: memory,
           pc: pc,
           running: _running,
           stack: stack
         } = state
       ) do
    instr = get_mem(memory, pc) |> lookup_instr()

    case instr do
      :add ->
        a = get_mem(memory, pc + 1)
        <<b::15>> = <<get_mem_or_reg(memory, pc + 2)::15>>
        <<c::15>> = <<get_mem_or_reg(memory, pc + 3)::15>>
        sum = rem(b + c, 32768)
        write_mem(memory, a, sum)
        %{state | :pc => pc + 4}

      :and ->
        a = get_mem(memory, pc + 1)
        b = get_mem_or_reg(memory, pc + 2)
        c = get_mem_or_reg(memory, pc + 3)
        <<b_or_c::15>> = <<Bitwise.band(b, c)::15>>
        write_mem(memory, a, b_or_c)
        %{state | :pc => pc + 4}

      :call ->
        a = get_mem_or_reg(memory, pc + 1)
        updated_stack = [pc + 2 | stack]
        %{state | :pc => a, :stack => updated_stack}

      :eq ->
        a = get_mem(memory, pc + 1)
        b = get_mem_or_reg(memory, pc + 2)
        c = get_mem_or_reg(memory, pc + 3)

        write_mem(
          memory,
          a,
          case b == c do
            true -> 1
            false -> 0
          end
        )

        %{state | :pc => pc + 4}

      :gt ->
        a = get_mem(memory, pc + 1)
        b = get_mem_or_reg(memory, pc + 2)
        c = get_mem_or_reg(memory, pc + 3)

        write_mem(
          memory,
          a,
          case b > c do
            true -> 1
            false -> 0
          end
        )

        %{state | :pc => pc + 4}

      :halt ->
        %{state | :running => false}

      :in ->
        input =
          case input_buffer do
            [] ->
              io.gets("") |> String.to_charlist()

            _ ->
              input_buffer
          end

        case input do
          'set reg8 42\n' ->
            write_mem(memory, 32775, 42)
            %{state | :input_buffer => []}

          [char | leftover] ->
            a = get_mem(memory, pc + 1)
            write_mem(memory, a, char)
            %{state | :pc => pc + 2, :input_buffer => leftover}
        end

      :jf ->
        a = get_mem_or_reg(memory, pc + 1)
        b = get_mem_or_reg(memory, pc + 2)

        updated_pc =
          case a do
            0 -> b
            _ -> pc + 3
          end

        %{state | :pc => updated_pc}

      :jmp ->
        a = get_mem_or_reg(memory, pc + 1)
        %{state | :pc => a}

      :jt ->
        a = get_mem_or_reg(memory, pc + 1)
        b = get_mem_or_reg(memory, pc + 2)

        updated_pc =
          case a do
            0 -> pc + 3
            _ -> b
          end

        %{state | :pc => updated_pc}

      :mod ->
        a = get_mem(memory, pc + 1)
        <<b::15>> = <<get_mem_or_reg(memory, pc + 2)::15>>
        <<c::15>> = <<get_mem_or_reg(memory, pc + 3)::15>>
        sum = rem(rem(b, c), 32768)
        write_mem(memory, a, sum)
        %{state | :pc => pc + 4}

      :mult ->
        a = get_mem(memory, pc + 1)
        <<b::15>> = <<get_mem_or_reg(memory, pc + 2)::15>>
        <<c::15>> = <<get_mem_or_reg(memory, pc + 3)::15>>
        sum = rem(b * c, 32768)
        write_mem(memory, a, sum)
        %{state | :pc => pc + 4}

      :noop ->
        %{state | :pc => pc + 1}

      :not ->
        a = get_mem(memory, pc + 1)
        b = get_mem_or_reg(memory, pc + 2)
        <<not_b::15>> = <<Bitwise.bnot(b)::15>>
        write_mem(memory, a, not_b)
        %{state | :pc => pc + 3}

      :or ->
        a = get_mem(memory, pc + 1)
        b = get_mem_or_reg(memory, pc + 2)
        c = get_mem_or_reg(memory, pc + 3)
        <<b_or_c::15>> = <<Bitwise.bor(b, c)::15>>
        write_mem(memory, a, b_or_c)
        %{state | :pc => pc + 4}

      :out ->
        c = get_mem_or_reg(memory, pc + 1)

        [c] |> List.to_string() |> io.write()
        %{state | :pc => pc + 2}

      :pop ->
        address = get_mem(memory, pc + 1)
        [val | popped_stack] = stack
        write_mem(memory, address, val)
        %{state | :pc => pc + 2, :stack => popped_stack}

      :push ->
        val = get_mem_or_reg(memory, pc + 1)
        %{state | :pc => pc + 2, :stack => [val | stack]}

      :ret ->
        case stack do
          [] -> %{state | :running => false}
          [val | popped_stack] -> %{state | :pc => val, :stack => popped_stack}
        end

      :rmem ->
        a = get_mem(memory, pc + 1)
        b = get_mem(memory, get_mem_or_reg(memory, pc + 2))
        write_mem(memory, a, b)
        %{state | :pc => pc + 3}

      :set ->
        address = get_mem(memory, pc + 1)
        val = get_mem_or_reg(memory, pc + 2)
        write_mem(memory, address, val)
        %{state | :pc => pc + 3}

      :wmem ->
        a = get_mem_or_reg(memory, pc + 1)
        b = get_mem_or_reg(memory, pc + 2)
        write_mem(memory, a, b)
        %{state | :pc => pc + 3}
    end
  end

  def write_mem(memory, address, val) do
    :ets.insert(memory, {address, val})
  end

  def get_mem(memory, address) do
    case :ets.lookup(memory, address) do
      [{address, val}] -> val
      _ -> 0
    end
  end

  defp get_mem_or_reg(memory, address) do
    get_mem(memory, address)
    |> case do
      val when val > 32767 -> get_mem(memory, val)
      val -> val
    end
  end

  def main() do
    load_program()
    |> run_program()
  end
end
