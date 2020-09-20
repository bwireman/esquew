defmodule Esquew.Api do
  use Plug.Router

  @moduledoc """
  Root of the Esquew API
  """

  @name __MODULE__

  defmodule APIResp do

    @moduledoc """
    Struct for API call response
    """
    @enforce_keys [:response]
    defstruct status: :ok, response: ""
  end

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  forward("/api/subscriptions", to: Esquew.Api.SubscriptionRouter)
  forward("/api", to: Esquew.Api.TopicRouter)

  def child_spec(opts) do
    %{
      id: @name,
      start: {@name, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    Plug.Cowboy.http(@name, [])
  end

  match _ do
    not_found(conn)
  end

  ## helpers

  def resp_boiler_plate(conn, code, resp) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, Poison.encode!(resp))
  end

  def not_found(conn) do
    resp_boiler_plate(conn, 404, %Esquew.Api.APIResp{status: :error, response: "Page not found"})
  end
end
