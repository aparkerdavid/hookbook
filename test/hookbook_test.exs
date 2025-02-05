defmodule HookbookTest do
  use ExUnit.Case
  doctest Hookbook

  test "greets the world" do
    assert Hookbook.hello() == :world
  end
end
