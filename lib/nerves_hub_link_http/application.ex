defmodule NervesHubLinkHTTP.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [NervesHubLinkHTTP.Connection]

    Supervisor.start_link(children, strategy: :one_for_one, name: NervesHubLinkHTTP.Supervisor)
  end
end
