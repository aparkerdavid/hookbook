defmodule Hookbook.QueryParams.EncodingTest do
  use ExUnit.Case
  doctest Hookbook.QueryParams.Encoding
  alias Hookbook.QueryParams.Encoding

  describe "decode" do
    test "decodes strings" do
      assert "foo" == Encoding.decode("foo", :string)
    end

    test "decodes integers" do
      assert 1 == Encoding.decode("1", :integer)
    end

    test "decodes floats" do
      assert 1.0 == Encoding.decode("1.0", :float)
    end

    test "decodes booleans" do
      assert true == Encoding.decode("true", :boolean)
      assert false == Encoding.decode("false", :boolean)
    end

    test "decodes sorts" do
      assert {:asc, :name} == Encoding.decode("asc:name", :sort)
      assert {:desc, :name} == Encoding.decode("desc:name", :sort)
    end
  end

  describe "encode" do
    test "encodes strings" do
      assert "foo" == Encoding.encode("foo", :string)
    end

    test "encodes integers" do
      assert "1" == Encoding.encode(1, :integer)
    end

    test "encodes floats" do
      assert "1.0" == Encoding.encode(1.0, :float)
    end

    test "encodes booleans" do
      assert "true" == Encoding.encode(true, :boolean)
      assert "false" == Encoding.encode(false, :boolean)
    end

    test "encodes sorts" do
      assert "asc:name" == Encoding.encode({:asc, :name}, :sort)
      assert "desc:name" == Encoding.encode({:desc, :name}, :sort)
    end
  end
end
