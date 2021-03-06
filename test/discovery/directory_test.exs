defmodule Discovery.DirectoryTest do
  use ExUnit.Case
  alias Discovery.Directory

  setup do
    on_exit fn ->
      Directory.clear
    end
  end

  test "services are empty" do
    assert Directory.services |> Enum.empty?
  end

  test "nodes are empty" do
    assert Directory.nodes |> Enum.empty?
  end

  test "adding a node and a service" do
    Directory.add(:'reset@undead', "router")
    services = Directory.services
    nodes    = Directory.nodes

    assert services |> Map.has_key?("router")
    assert nodes |> Map.has_key?(:'reset@undead')
    assert nodes[:'reset@undead'] |> Set.member?("router")
    assert nodes |> Enum.count == 1
    assert services["router"] |> Set.member?(:'reset@undead')
    assert services |> Enum.count == 1

    Directory.add(:'reset@undead', "router")
    services = Directory.services
    nodes    = Directory.nodes

    assert services |> Enum.count == 1
    assert nodes |> Enum.count == 1
  end

  test "add/3 when the directory is not running on the remote node it does not raise" do
    result = Directory.add(:'reset@undead', Node.self, "router")
    assert elem(result, 0) == :error
  end

  test "removing a node" do
    Directory.add(:'reset@undead', "router")
    Directory.drop(:'reset@undead')

    assert Directory.services |> Enum.empty?
    assert Directory.nodes |> Enum.empty?
  end

  test "dropping a node and all services it was providing" do
    Directory.add(:'reset@undead', "router")
    Directory.add(:'reset@undead', "account")
    Directory.add(:'reset-2@undead', "router")
    Directory.drop(:'reset@undead')

    refute Directory.nodes |> Enum.empty?
    assert Directory.nodes |> Dict.has_key?(:'reset-2@undead')
    assert Directory.nodes[:'reset-2@undead'] |> Set.size == 1
    assert Directory.nodes[:'reset-2@undead'] |> Set.member?("router")
    refute Directory.rings |> Dict.has_key?("account")
    assert Directory.rings |> Dict.has_key?("router")
  end

  test "removing multiple services that a node was providing" do
    Directory.add(:'reset@undead', "router")
    Directory.add(:'reset@undead', "account")
    Directory.add(:'reset-2@undead', "router")
    Directory.drop(:'reset@undead', "router")
    Directory.drop(:'reset@undead', "account")

    refute Directory.services |> Dict.has_key?("account")
    assert Directory.services |> Dict.has_key?("router")
    assert Directory.nodes |> Dict.has_key?(:'reset-2@undead')
    refute Directory.nodes |> Dict.has_key?(:'reset@undead')
    refute Directory.rings |> Dict.has_key?("account")
    assert Directory.rings |> Dict.has_key?("router")
  end

  test "adding a node providing multiple services" do
    Directory.add(:'reset@undead', "router")
    Directory.add(:'reset@undead', "chat")
    Directory.add(:'reset@undead', "account")
    services = Directory.services
    nodes    = Directory.nodes

    assert services |> Enum.count == 3
    assert nodes |> Enum.count == 1
  end

  test "removing a node providing multiple services" do
    Directory.add(:'reset@undead', "router")
    Directory.add(:'reset@undead', "chat")
    Directory.add(:'reset@undead', "account")
    Directory.drop(:'reset@undead')

    assert Directory.services |> Enum.empty?
    assert Directory.nodes |> Enum.empty?
  end

  test "adding multiple nodes providing multiple services" do
    Directory.add(:'reset@undead', "router")
    Directory.add(:'reset@undead', "chat")
    Directory.add(:'reset-2@undead', "account")
    Directory.add(:'reset-2@undead', "router")
    nodes    = Directory.nodes
    services = Directory.services

    assert nodes |> Enum.count == 2
    assert services |> Enum.count == 3
    assert nodes[:'reset@undead'] |> Enum.count == 2
    assert nodes[:'reset-2@undead'] |> Enum.count == 2
    assert services["router"] |> Enum.count == 2
    assert services["chat"] |> Enum.count == 1
    assert services["account"] |> Enum.count == 1
  end

  test "removing multiple nodes providing multiple services" do
    Directory.add(:'reset@undead', "router")
    Directory.add(:'reset@undead', "chat")
    Directory.add(:'reset-2@undead', "account")
    Directory.add(:'reset-2@undead', "router")
    Directory.drop(:'reset@undead')
    nodes    = Directory.nodes
    services = Directory.services

    assert nodes |> Enum.count == 1
    assert services |> Enum.count == 2
    assert services["account"] |> Enum.count == 1
    assert services["account"] |> Set.member?(:'reset-2@undead')
    assert services["router"] |> Enum.count == 1
    assert services["router"] |> Set.member?(:'reset-2@undead')

    Directory.drop(:'reset-2@undead')

    assert Directory.nodes |> Enum.empty?
    assert Directory.services |> Enum.empty?
  end

  test "adding a node and service multiple times" do
    Directory.add(:'reset@undead', "router")
    assert Directory.add(:'reset@undead', "router") == :ok
    assert Directory.nodes |> Enum.count == 1
    assert Directory.services |> Enum.count == 1
  end

  test "retreiving nodes that are providing a particular service" do
    Directory.add(:'reset@undead', "router")
    Directory.add(:'reset-2@undead', "router")
    Directory.add(:'reset@undead', "chat")

    nodes = Directory.nodes("router")
    assert Enum.count(nodes) == 2
    assert Enum.member?(nodes, :'reset@undead')
    assert Enum.member?(nodes, :'reset-2@undead')

    nodes = Directory.nodes("chat")
    assert Enum.count(nodes) == 1
    assert Enum.member?(nodes, :'reset@undead')

    nodes = Directory.nodes("something")
    assert Enum.count(nodes) == 0

    nodes = Directory.nodes(["router", "chat"])
    assert Enum.count(nodes) == 3
  end

  test "listing all services that a given node provides" do
    Directory.add(:'reset@undead', "router")
    Directory.add(:'reset@undead', "chat")
    Directory.add(:'reset@undead-2', "router")

    assert Directory.services(:'reset@undead') |> Enum.count == 2
  end

  test "has_node?/1" do
    Directory.add(:'reset@undead', "router")

    assert Directory.has_node?(:'reset@undead')
    refute Directory.has_node?(:'reset-2@undead')
  end

  test "has_node?/2" do
    Directory.add(:'reset@undead', "router")
    assert Directory.has_node?(:'reset@undead', "router")
    refute Directory.has_node?(:'reset@undead', "account")
  end
end
