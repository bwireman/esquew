defmodule Esquew.HubTest do
  use ExUnit.Case

  @test_hub_topic "TestHubTopic"
  @test_hub_topic2 "TestHubTopic2"
  @test_hub_sub "TestHubSub"
  @test_hub_sub2 "TestHubSub2"

  test "creates new topics and subscriptions" do
    assert Esquew.Hub.add_topic(@test_hub_topic) === {:ok, {@test_hub_topic, []}}
    assert Esquew.Hub.add_topic(@test_hub_topic2) === {:ok, {@test_hub_topic2, []}}

    assert Esquew.Hub.add_subscription(@test_hub_topic, @test_hub_sub) ===
             {:ok, {@test_hub_topic, [@test_hub_sub]}}

    assert Esquew.Hub.add_subscription(@test_hub_topic, @test_hub_sub2) ===
             {:ok, {@test_hub_topic, [@test_hub_sub2, @test_hub_sub]}}
  end
end
