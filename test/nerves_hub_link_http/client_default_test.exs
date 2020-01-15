defmodule NervesHubLinkHTTP.Client.DefaultTest do
  use ExUnit.Case, async: true
  alias NervesHubLinkHTTP.Client.Default

  doctest Default

  test "handle_error/1" do
    assert Default.handle_error(:error) == :ok
  end

  describe "handle_fwup_message/1" do
    test "progress" do
      assert Default.handle_fwup_message({:progress, 25}) == :ok
    end

    test "error" do
      assert Default.handle_fwup_message({:error, :any, "message"}) == :ok
    end

    test "warning" do
      assert Default.handle_fwup_message({:warning, :any, "message"}) == :ok
    end

    test "any" do
      assert Default.handle_fwup_message(:any) == :ok
    end
  end

  describe "request/4" do
    test "hackney.request/5 error" do
      assert Default.request(:get, "file://nope", [], []) == {:error, {:error, :nxdomain}}
    end
  end
end
