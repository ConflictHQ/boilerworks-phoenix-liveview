defmodule Boilerworks.Mailer do
  @moduledoc """
  Placeholder mailer module. In production, configure Swoosh adapter.
  For now, log-based delivery for development.
  """

  def deliver(to, subject, body) do
    require Logger
    Logger.info("Email to #{to}: #{subject}\n#{body}")
    {:ok, %{to: to, subject: subject}}
  end
end
