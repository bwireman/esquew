defmodule Esquew.Api.SubscriptionRouter do
  import Plug.Conn
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/read/:topic/:subscription" do
    count =
      case Map.get(conn.params, "count") do
        nil -> 1
        val -> String.to_integer(val)
      end

    messages = Esquew.Subscription.read(topic, subscription, count)

    resp = %{
      messages:
        Enum.map(messages, fn {ref, msg} ->
          %{ref: ref, message: msg}
        end)
    }

    Esquew.Api.resp_boiler_plate(conn, 200, resp)
  end

  post "/ack/:topic/:subscription" do
    ack_or_nack(conn, &(Esquew.Subscription.ack(topic, subscription, &1)))
  end

  post "/nack/:topic/:subscription" do
    ack_or_nack(conn, &(Esquew.Subscription.nack(topic, subscription, &1)))
  end

  match _ do
    send_resp(conn, 404, "Requested page not found!")
  end

  ## private functions

  defp ack_or_nack(conn, func) do
    {code, resp} =
      case conn.body_params do
        %{"refs" => refs} ->
          Enum.map(refs, &func.(&1))
          {200, %Esquew.Api.APIResp{response: refs}}

        _ ->
          {400, %Esquew.Api.APIResp{status: :error, response: "Invalid format"}}
      end

    Esquew.Api.resp_boiler_plate(conn, code, resp)
  end
end
