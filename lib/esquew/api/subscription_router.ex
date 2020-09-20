defmodule Esquew.Api.SubscriptionRouter do
  import Plug.Conn
  use Plug.Router

  @moduledoc """
  Module for subscription related api calls
  """

  plug(:match)
  plug(:dispatch)

  get "/read/:topic/:subscription" do
    count =
      case Map.get(conn.params, "count") do
        nil -> 1
        val -> String.to_integer(val)
      end

    {code, resp} =
      case Esquew.Subscription.read(topic, subscription, count) do
        {:ok, messages} ->
          {200,
           %{
             messages:
               Enum.map(messages, fn {ref, msg} ->
                 %{ref: ref, message: msg}
               end)
           }}

        {:error, error} ->
          {400, %Esquew.Api.APIResp{status: :error, response: error}}
      end

    Esquew.Api.resp_boiler_plate(conn, code, resp)
  end

  post "/ack/:topic/:subscription" do
    ack_or_nack(conn, &Esquew.Subscription.ack(topic, subscription, &1))
  end

  post "/nack/:topic/:subscription" do
    ack_or_nack(conn, &Esquew.Subscription.nack(topic, subscription, &1))
  end

  match _ do
    Esquew.Api.not_found(conn)
  end

  ## private functions

  defp ack_or_nack(conn, func) do
    {code, resp} =
      case conn.body_params do
        %{"refs" => refs} ->
          Enum.each(refs, &func.(&1))
          {200, %Esquew.Api.APIResp{response: refs}}

        _ ->
          {400, %Esquew.Api.APIResp{status: :error, response: "Invalid format"}}
      end

    Esquew.Api.resp_boiler_plate(conn, code, resp)
  end
end
