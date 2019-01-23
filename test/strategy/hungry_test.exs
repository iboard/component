defmodule Test.Strategy.Hungry do
  use ExUnit.Case

  alias __MODULE__.Adder, as: HA

  setup do
    HA.initialize()
    :ok
  end

  test "basic operation" do
    assert HA.consume([1, 2, "cat"]) == [3, 6, "catcat"]
  end

  test "supports into" do
    assert HA.consume([a: :b, c: :d], into: %{}) == %{b: :a, d: :c}
  end

  test "into function" do
    HA.consume([:a, :b, :c, :d, :e, :f],
      into: fn x ->
        assert x in ~w{ a b c d e f }
      end
    )
  end

  test "into stream" do
    stream = HA.consume([:a, :b, :c, :d, :e, :f], into: :stream)
    assert %Stream{} = stream
    assert Enum.into(stream, []) == ~w{ a b c d e f }
  end

  test "schedules workers" do
    assert HA.consume(1..100) == 1..100 |> Enum.map(&(&1 * 3))
  end

  test "when_done function called" do
    send_result = fn x -> send(self(), {:got, x |> Enum.to_list()}) end
    assert HA.consume([1, 2, "cat"], when_done: send_result) == [3, 6, "catcat"]
    assert_receive({:got, [3, 6, "catcat"]})
  end

  defmodule Adder do
    use Component.Strategy.Hungry,
      show_code: false,
      concurrency: 5

    def process(val) when is_number(val) do
      val * 3
    end

    def process(val) when is_binary(val) do
      val <> val
    end

    def process(val) when is_atom(val) do
      "#{val}"
    end

    def process({a, b}), do: {b, a}
  end
end
