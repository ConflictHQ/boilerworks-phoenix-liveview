defmodule Boilerworks.Features do
  @moduledoc """
  Feature toggles. Controlled via environment variables.
  """

  def enabled?(:forms), do: System.get_env("FEATURE_FORMS") == "true"
  def enabled?(:workflows), do: System.get_env("FEATURE_WORKFLOWS") == "true"
  def enabled?(_), do: false
end
