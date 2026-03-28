defmodule BoilerworksWeb.AuthorizationTest do
  use BoilerworksWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExUnit.CaptureLog

  describe "unauthenticated access" do
    test "redirects to login from /products", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/products")
    end

    test "redirects to login from / (dashboard)", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/login"}}} = live(conn, ~p"/")
    end
  end

  describe "viewer permission boundaries" do
    setup :register_and_log_in_viewer

    test "viewer can access /products (has product.view)", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/products")
      assert html =~ "Products"
    end

    test "viewer cannot save a new product via the create form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/products/new")

      Process.flag(:trap_exit, true)

      assert capture_log(fn ->
               catch_exit(
                 view
                 |> form("#product-form", product: %{name: "Denied Product", price: "9.99"})
                 |> render_submit()
               )
             end) =~ "ForbiddenError"
    end

    test "viewer cannot delete a product", %{conn: conn} do
      product = product_fixture(%{"name" => "Delete Target"})
      {:ok, view, _html} = live(conn, ~p"/products")

      Process.flag(:trap_exit, true)

      assert capture_log(fn ->
               catch_exit(render_click(view, "delete", %{"id" => product.id}))
             end) =~ "ForbiddenError"
    end

    test "viewer cannot trigger a workflow transition", %{conn: conn, user: viewer} do
      setup_user_with_permissions(viewer, ~w(workflow.view))

      admin = user_fixture()
      setup_user_permissions(admin)

      {:ok, wf} =
        Boilerworks.Workflows.create_workflow_definition(
          %{
            "name" => "Auth Test WF",
            "initial_state" => "draft",
            "states" => %{
              "draft" => %{"label" => "Draft"},
              "review" => %{"label" => "In Review"}
            },
            "transitions" => [
              %{"name" => "submit", "from" => "draft", "to" => "review", "label" => "Submit"}
            ]
          },
          admin
        )

      {:ok, instance} = Boilerworks.Workflows.create_instance(wf, %{}, admin)

      {:ok, view, _html} = live(conn, ~p"/workflows/#{wf}")

      Process.flag(:trap_exit, true)

      assert capture_log(fn ->
               catch_exit(
                 render_click(view, "transition", %{
                   "instance_id" => instance.id,
                   "transition" => "submit"
                 })
               )
             end) =~ "ForbiddenError"
    end

    test "viewer denied access to /forms (no form.view permission)", %{conn: conn} do
      assert_raise BoilerworksWeb.ForbiddenError, fn ->
        live(conn, ~p"/forms")
      end
    end
  end
end
