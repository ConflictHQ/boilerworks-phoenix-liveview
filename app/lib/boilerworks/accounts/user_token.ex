defmodule Boilerworks.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @rand_size 32
  @session_validity_in_days 60

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, Boilerworks.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %__MODULE__{token: token, context: "session", user_id: user.id}}
  end

  def verify_session_token_query(token) do
    from token in by_token_and_context_query(token, "session"),
      where: token.inserted_at > ago(@session_validity_in_days, "day"),
      join: user in assoc(token, :user),
      select: user
  end

  def by_token_and_context_query(token, context) do
    from __MODULE__, where: [token: ^token, context: ^context]
  end

  def by_user_and_contexts_query(user, :all) do
    from t in __MODULE__, where: t.user_id == ^user.id
  end

  def by_user_and_contexts_query(user, [_ | _] = contexts) do
    from t in __MODULE__, where: t.user_id == ^user.id and t.context in ^contexts
  end
end
