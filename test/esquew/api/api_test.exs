defmodule Esquew.Api.SubscriptionRouterTest do
  use ExUnit.Case
  use Plug.Test
  @opts Esquew.Api.init([])

  @test_topic "APITestTopic"
  @test_subscription "APITestSubscription"
  @test_message "message"

  defp make_call(method, route, data \\ "") do
    method
    |> conn(route, data)
    |> Esquew.Api.call(@opts)
  end

  defp test_conn(conn, status, body \\ nil) do
    assert conn.state == :sent
    assert conn.status == status

    if body != nil do
      assert conn.resp_body == body
    end
  end

  test "create topic" do
    conn =
      make_call(:post, "/api/create", %{topic: @test_topic, subscriptions: [@test_subscription]})

    test_conn(
      conn,
      200,
      Poison.encode!(%Esquew.Api.APIResp{
        response: "Added topic APITestTopic, and subscription(s) APITestSubscription"
      })
    )

    conn = make_call(:post, "/api/publish/fake", %{message: @test_message})

    test_conn(
      conn,
      400,
      Poison.encode!(%Esquew.Api.APIResp{
        status: :error,
        response: "Unable to send message to topic: fake"
      })
    )

    conn = make_call(:post, "/api/publish/#{@test_topic}", %{message: @test_message})

    test_conn(
      conn,
      200,
      Poison.encode!(%Esquew.Api.APIResp{response: "Message sent"})
    )

    conn = make_call(:get, "/api/subscriptions/read/#{@test_topic}/#{@test_subscription}")

    test_conn(conn, 200)

    %{"messages" => [%{"ref" => ref, "message" => message}]} = Poison.decode!(conn.resp_body)
    assert message == @test_message

    conn =
      make_call(:post, "/api/subscriptions/nack/#{@test_topic}/#{@test_subscription}", %{
        "refs" => [ref]
      })

    test_conn(
      conn,
      200,
      Poison.encode!(%Esquew.Api.APIResp{response: [ref]})
    )

    conn =
      make_call(:post, "/api/subscriptions/ack/#{@test_topic}/#{@test_subscription}", %{
        "refs" => [ref]
      })

    test_conn(
      conn,
      200,
      Poison.encode!(%Esquew.Api.APIResp{response: [ref]})
    )

    conn = make_call(:get, "/api/subscriptions/read/#{@test_topic}/#{@test_subscription}")

    test_conn(conn, 200)

    %{"messages" => [%{"ref" => ref, "message" => message}]} = Poison.decode!(conn.resp_body)
    assert message == @test_message

    conn =
      make_call(:post, "/api/subscriptions/ack/#{@test_topic}/#{@test_subscription}", %{
        "refs" => [ref]
      })

    test_conn(
      conn,
      200,
      Poison.encode!(%Esquew.Api.APIResp{response: [ref]})
    )

    conn = make_call(:get, "/api/subscriptions/read/#{@test_topic}/#{@test_subscription}")
    test_conn(conn, 200, Poison.encode!(%{"messages" => []}))
  end
end
