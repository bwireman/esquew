defmodule Esquew.Api do
  use Plug.Router

  @name __MODULE__

  defmodule APIResp do
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
    send_resp(conn, 404, "Requested page not found!")
  end

  ## helpers

  def resp_boiler_plate(conn, code, resp) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, Poison.encode!(resp))
  end
end
