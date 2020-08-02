defmodule EctoSumEmbed do
  @moduledoc """
  Documentation for `EctoSumEmbed`.
  """

  defmacro __using__(opts) do
    list =
      Keyword.fetch!(opts, :one_of)
      |> Enum.map(fn elem ->
        %{
          module: elem |> Keyword.fetch!(:module) |> Macro.expand(__CALLER__),
          label: elem |> Keyword.fetch!(:label)
        }
      end)
      |> Macro.escape()

    quote do
      use Ecto.Type

      @list unquote(list)

      def type, do: :map

      def cast(attrs) when is_struct(attrs), do: {:ok, attrs}

      def cast(attrs) when is_map(attrs) do
        attrs = attrs |> conv_field_keys()
        module = get_module_from_data(attrs)
        maybe_change(module, attrs)
      end

      defp maybe_change(module, attrs) do
        module.changeset(module.__struct__, attrs)
        |> maybe_apply_changes()
      end

      defp maybe_apply_changes(changeset) do
        if changeset.valid? do
          {:ok, Ecto.Changeset.apply_changes(changeset)}
        else
          {:error, changeset.errors}
        end
      end

      def cast(_), do: :error

      def load(data) when is_map(data) do
        get_struct_from_data(data)
      end

      def load(_), do: :error

      def dump(struct) when is_struct(struct) do
        {:ok, get_map_from_struct(struct)}
      end

      def dump(_), do: :error

      defp conv_field_keys(attrs) do
        attrs |> Enum.into(%{}, fn {k, v} -> {cast_key(k), v} end)
      end

      defp cast_key(key) when is_atom(key), do: Atom.to_string(key)
      defp cast_key(key) when is_binary(key), do: key

      defp get_module_from_data(%{"__type__" => type} = data) do
        @list
        |> Enum.find(&(&1.label == type))
        |> Map.fetch!(:module)
      end

      defp get_struct_from_data(data) do
        get_module_from_data(data)
        |> maybe_change(data)
      end

      defp get_map_from_struct(%module{} = struct) do
        struct
        |> Map.from_struct()
        |> Map.put(:__type__, get_label_from_module(module))
      end

      defp get_label_from_module(module) do
        @list
        |> Enum.find(&(&1.module == module))
        |> Map.fetch!(:label)
      end
    end
  end

  @spec put_type(map(), binary()) :: map()
  def put_type(data, label) do
    Map.put(data, :__type__, label)
  end
end
