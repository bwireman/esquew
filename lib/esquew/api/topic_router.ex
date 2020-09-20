defmodule Esquew.Api.TopicRouter do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    Esquew.Api.resp_boiler_plate(conn, 200, Esquew.Hub.list())
  end

  post "/create" do
    {code, resp} =
      case conn.body_params do
        %{"topic" => topic, "subscriptions" => subs} ->
          Esquew.Hub.add_topic(topic)
          Enum.map(subs, &Esquew.Hub.add_subscription(topic, &1))

          {200,
           %Esquew.Api.APIResp{
             response: "Added topic #{topic}, and subscription #{subs}"
           }}

        _ ->
          {400, %Esquew.Api.APIResp{status: :error, response: "Invalid format"}}
      end

    Esquew.Api.resp_boiler_plate(conn, code, resp)
  end

  post "/publish/:topic" do
    {code, resp} =
      case conn.body_params do
        %{"message" => message} ->
          case Esquew.Topic.publish(topic, message) do
            :ok ->
              {200, %Esquew.Api.APIResp{response: "Message sent"}}

            _ ->
              {400,
               %Esquew.Api.APIResp{
                 status: :error,
                 response: "Unable to send message to topic: #{topic}"
               }}
          end

        _ ->
          {400, %Esquew.Api.APIResp{status: :error, response: "Invalid format"}}
      end

    Esquew.Api.resp_boiler_plate(conn, code, resp)
  end

  match _ do
    send_resp(conn, 404, "Requested page not found!")
  end
end
