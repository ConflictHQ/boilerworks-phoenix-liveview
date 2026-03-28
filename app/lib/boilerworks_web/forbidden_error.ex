defmodule BoilerworksWeb.ForbiddenError do
  defexception message: "Forbidden", plug_status: 403
end
