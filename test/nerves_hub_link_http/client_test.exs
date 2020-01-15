defmodule NervesHubLinkHTTP.ClientTest do
  use ExUnit.Case, async: true
  alias NervesHubLinkHTTP.{Client, ClientMock}

  doctest Client

  setup context, do: Mox.verify_on_exit!(context)

  test "handle_fwup_message/2" do
    Mox.expect(ClientMock, :handle_fwup_message, fn :data -> :ok end)
    assert Client.handle_fwup_message(:data) == :ok
  end

  test "handle_error/2" do
    Mox.expect(ClientMock, :handle_error, fn :data -> :ok end)
    assert Client.handle_error(:data) == :ok
  end

  describe "apply_wrap doesn't propagate failures" do
    test "error" do
      Mox.expect(ClientMock, :handle_fwup_message, fn :data -> raise :something end)
      assert Client.handle_fwup_message(:data) == :ok
    end

    test "exit" do
      Mox.expect(ClientMock, :handle_fwup_message, fn :data -> exit(:reason) end)
      assert Client.handle_fwup_message(:data) == :ok
    end

    test "throw" do
      Mox.expect(ClientMock, :handle_fwup_message, fn :data -> throw(:reason) end)
      assert Client.handle_fwup_message(:data) == :ok
    end

    test "exception" do
      Mox.expect(ClientMock, :handle_fwup_message, fn :data -> Not.real() end)
      assert Client.handle_fwup_message(:data) == :ok
    end
  end

  test "me/0" do
    url = Client.url("/device/me")

    Mox.expect(ClientMock, :request, fn :get, ^url, _, _, _ ->
      {:ok, :response}
    end)

    assert Client.me() == {:ok, :response}
  end

  test "update/0" do
    url = Client.url("/device/update")

    Mox.expect(ClientMock, :request, fn :get, ^url, _, _, _ ->
      {:ok, :response}
    end)

    assert Client.update() == {:ok, :response}
  end

  describe "request/3" do
    test ":get with params" do
      params = %{key: :val}
      url = "#{Client.url("/path")}?#{URI.encode_query(params)}"

      Mox.expect(ClientMock, :request, fn :get, ^url, _, _, _ ->
        {:ok, :response}
      end)

      assert Client.request(:get, "/path", params) == {:ok, :response}
    end

    test "non :get with params" do
      params = %{key: :val}
      url = Client.url("/path")
      body = Jason.encode!(params)

      Mox.expect(ClientMock, :request, fn :put, ^url, _, ^body, _ ->
        {:ok, :response}
      end)

      assert Client.request(:put, "/path", params) == {:ok, :response}
    end

    test "no params" do
      url = Client.url("/path")

      Mox.expect(ClientMock, :request, fn :get, ^url, _, [], _ ->
        {:ok, :response}
      end)

      assert Client.request(:get, "/path", []) == {:ok, :response}
    end
  end

  test "url/1" do
    assert Client.url("/test/me") == "https://0.0.0.0:4001/test/me"
  end
end
