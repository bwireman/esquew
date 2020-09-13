defmodule Esquew.SubscriptionTest do
  use ExUnit.Case

  @test_topic "SubscriptionTestTopic"
  @test_sub1 "TestSub1"
  @test_sub2 "TestSub2"

  setup do
    {:ok, _} = Esquew.Hub.add_topic(@test_topic)
    {:ok, _} = Esquew.Hub.add_subscription(@test_topic, @test_sub1)
    {:ok, _} = Esquew.Hub.add_subscription(@test_topic, @test_sub2)
    :ok
  end

  test "publishes to topics can be read from all subscriptions acked and nacked" do
    Esquew.Hub.publish(@test_topic, "M2")
    [{ref, message}] = Esquew.Subscription.read(@test_topic, @test_sub1)
    assert message === "M2"
    assert Esquew.Subscription.read(@test_topic, @test_sub1) === []
    assert Esquew.Subscription.ack(@test_topic, @test_sub1, ref) === :ok
    assert Esquew.Subscription.read(@test_topic, @test_sub1) === []

    [{ref, message}] = Esquew.Subscription.read(@test_topic, @test_sub2)
    assert message === "M2"
    assert Esquew.Subscription.read(@test_topic, @test_sub2) === []
    assert Esquew.Subscription.ack(@test_topic, @test_sub2, ref) === :ok
    assert Esquew.Subscription.read(@test_topic, @test_sub2) === []

    Esquew.Hub.publish(@test_topic, "M3")
    [{ref, message}] = Esquew.Subscription.read(@test_topic, @test_sub1)
    assert message === "M3"
    assert Esquew.Subscription.read(@test_topic, @test_sub1) === []
    assert Esquew.Subscription.nack(@test_topic, @test_sub1, ref) === :ok
    Process.sleep(1000)
    [{_, message}] = Esquew.Subscription.read(@test_topic, @test_sub1)
    assert message === "M3"

    [{ref, message}] = Esquew.Subscription.read(@test_topic, @test_sub2)
    assert message === "M3"
    assert Esquew.Subscription.read(@test_topic, @test_sub2) === []
    assert Esquew.Subscription.nack(@test_topic, @test_sub2, ref) === :ok
    Process.sleep(1000)
    [{_, message}] = Esquew.Subscription.read(@test_topic, @test_sub2)
    assert message === "M3"
  end
end
