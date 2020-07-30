defmodule EctoSum do
  @moduledoc """
  Documentation for `EctoSum`.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Type
    end
  end
end
