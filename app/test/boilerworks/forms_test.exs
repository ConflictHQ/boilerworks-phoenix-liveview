defmodule Boilerworks.FormsTest do
  use Boilerworks.DataCase

  alias Boilerworks.Forms

  def user_fixture do
    {:ok, user} =
      Boilerworks.Accounts.register_user(%{
        email: "forms-#{System.unique_integer([:positive])}@example.com",
        password: "password1234"
      })

    user
  end

  def form_definition_fixture(user \\ nil) do
    user = user || user_fixture()

    {:ok, form_def} =
      Forms.create_form_definition(
        %{
          "name" => "Test Form #{System.unique_integer([:positive])}",
          "schema" => %{
            "fields" => [
              %{"name" => "name", "type" => "text", "label" => "Name", "required" => true},
              %{"name" => "email", "type" => "email", "label" => "Email", "required" => true},
              %{"name" => "notes", "type" => "textarea", "label" => "Notes"}
            ]
          }
        },
        user
      )

    form_def
  end

  describe "form_definitions" do
    test "list_form_definitions/0 returns non-deleted forms" do
      user = user_fixture()
      form_def = form_definition_fixture(user)
      forms = Forms.list_form_definitions()
      assert Enum.any?(forms, fn f -> f.id == form_def.id end)
    end

    test "create_form_definition/2 validates schema" do
      user = user_fixture()

      assert {:error, changeset} =
               Forms.create_form_definition(
                 %{"name" => "Bad Form", "schema" => %{"invalid" => true}},
                 user
               )

      assert errors_on(changeset).schema != []
    end

    test "delete_form_definition/1 soft deletes" do
      form_def = form_definition_fixture()
      {:ok, deleted} = Forms.delete_form_definition(form_def)
      assert deleted.deleted_at != nil
    end
  end

  describe "submissions" do
    test "create_submission/2 stores form data" do
      user = user_fixture()
      form_def = form_definition_fixture(user)

      {:ok, submission} =
        Forms.create_submission(
          %{
            "data" => %{"name" => "John", "email" => "john@example.com"},
            "form_definition_id" => form_def.id,
            "status" => "submitted"
          },
          user
        )

      assert submission.data["name"] == "John"
      assert submission.status == "submitted"
    end
  end

  describe "validate_submission_data/2" do
    test "validates required fields" do
      form_def = form_definition_fixture()
      assert {:error, errors} = Forms.validate_submission_data(form_def, %{})
      assert Enum.any?(errors, fn {field, _} -> field == "name" end)
      assert Enum.any?(errors, fn {field, _} -> field == "email" end)
    end

    test "passes with all required fields" do
      form_def = form_definition_fixture()

      assert :ok =
               Forms.validate_submission_data(form_def, %{"name" => "John", "email" => "j@e.com"})
    end
  end
end
