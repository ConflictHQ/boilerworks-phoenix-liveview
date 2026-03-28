defmodule BoilerworksWeb.ProductLiveTest do
  use BoilerworksWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  describe "Index" do
    test "lists products", %{conn: conn} do
      _product = product_fixture(%{"name" => "Test Widget"})
      {:ok, _view, html} = live(conn, ~p"/products")
      assert html =~ "Products"
      assert html =~ "Test Widget"
    end

    test "searches products", %{conn: conn} do
      product_fixture(%{"name" => "Alpha Gadget"})
      product_fixture(%{"name" => "Beta Widget"})

      {:ok, view, _html} = live(conn, ~p"/products")

      html =
        view
        |> element("form")
        |> render_change(%{"search" => "Alpha"})

      assert html =~ "Alpha Gadget"
      refute html =~ "Beta Widget"
    end
  end
end
