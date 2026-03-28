defmodule Boilerworks.WorkflowsTest do
  use Boilerworks.DataCase

  alias Boilerworks.Workflows

  def user_fixture do
    {:ok, user} =
      Boilerworks.Accounts.register_user(%{
        email: "wf-#{System.unique_integer([:positive])}@example.com",
        password: "password1234"
      })

    user
  end

  def workflow_definition_fixture(user \\ nil) do
    user = user || user_fixture()

    {:ok, wf} =
      Workflows.create_workflow_definition(
        %{
          "name" => "Test Workflow #{System.unique_integer([:positive])}",
          "initial_state" => "draft",
          "states" => %{
            "draft" => %{"label" => "Draft"},
            "review" => %{"label" => "In Review"},
            "approved" => %{"label" => "Approved", "terminal" => true},
            "rejected" => %{"label" => "Rejected"}
          },
          "transitions" => [
            %{"name" => "submit", "from" => "draft", "to" => "review", "label" => "Submit"},
            %{"name" => "approve", "from" => "review", "to" => "approved", "label" => "Approve"},
            %{"name" => "reject", "from" => "review", "to" => "rejected", "label" => "Reject"},
            %{"name" => "revise", "from" => "rejected", "to" => "draft", "label" => "Revise"}
          ]
        },
        user
      )

    wf
  end

  describe "workflow_definitions" do
    test "create_workflow_definition/2 creates with valid data" do
      user = user_fixture()
      wf = workflow_definition_fixture(user)
      assert wf.initial_state == "draft"
      assert map_size(wf.states) == 4
      assert length(wf.transitions) == 4
    end

    test "rejects invalid initial state" do
      user = user_fixture()

      assert {:error, changeset} =
               Workflows.create_workflow_definition(
                 %{
                   "name" => "Bad WF",
                   "initial_state" => "nonexistent",
                   "states" => %{"draft" => %{"label" => "Draft"}},
                   "transitions" => []
                 },
                 user
               )

      assert errors_on(changeset).initial_state != []
    end
  end

  describe "instances and transitions" do
    test "create_instance/3 starts at initial state" do
      user = user_fixture()
      wf = workflow_definition_fixture(user)
      {:ok, instance} = Workflows.create_instance(wf, %{}, user)
      assert instance.current_state == "draft"
    end

    test "transition/3 moves to valid state" do
      user = user_fixture()
      wf = workflow_definition_fixture(user)
      {:ok, instance} = Workflows.create_instance(wf, %{}, user)

      {:ok, updated} = Workflows.transition(instance, "submit", user)
      assert updated.current_state == "review"
    end

    test "transition/3 rejects invalid transition" do
      user = user_fixture()
      wf = workflow_definition_fixture(user)
      {:ok, instance} = Workflows.create_instance(wf, %{}, user)

      # Can't approve from draft
      assert {:error, :invalid_transition} = Workflows.transition(instance, "approve", user)
    end

    test "transition/3 marks terminal state as completed" do
      user = user_fixture()
      wf = workflow_definition_fixture(user)
      {:ok, instance} = Workflows.create_instance(wf, %{}, user)

      {:ok, in_review} = Workflows.transition(instance, "submit", user)
      {:ok, approved} = Workflows.transition(in_review, "approve", user)

      assert approved.completed_at != nil
    end

    test "transition/3 creates transition log" do
      user = user_fixture()
      wf = workflow_definition_fixture(user)
      {:ok, instance} = Workflows.create_instance(wf, %{}, user)

      {:ok, _updated} = Workflows.transition(instance, "submit", user)

      loaded = Workflows.get_instance!(instance.id)
      assert length(loaded.transition_logs) == 1
      log = hd(loaded.transition_logs)
      assert log.from_state == "draft"
      assert log.to_state == "review"
      assert log.transition_name == "submit"
    end

    test "available_transitions/1 returns valid transitions for current state" do
      user = user_fixture()
      wf = workflow_definition_fixture(user)
      {:ok, instance} = Workflows.create_instance(wf, %{}, user)

      transitions = Workflows.available_transitions(instance)
      assert length(transitions) == 1
      assert hd(transitions)["name"] == "submit"
    end
  end
end
