defmodule Vix.Vips.Operation do
  @moduledoc """
  Vips Operations

  See libvips
  [documentation](https://libvips.github.io/libvips/API/current/func-list.html)
  for more detailed description of the operation.

  Vips operation functions are generated using vips-introspection and
  are up-to-date with libvips version installed. Documentation in the
  hexdocs might *not* match for you.
  """

  import Vix.Vips.OperationHelper

  defmodule Error do
    defexception [:message]
  end

  # define typespec for enums
  Enum.map(vips_enum_list(), fn {name, enum} ->
    {enum_str_list, _} = Enum.unzip(enum)
    @type unquote(type_name(name)) :: unquote(atom_typespec_ast(enum_str_list))
  end)

  # define typespec for flags
  Enum.map(vips_flag_list(), fn {name, flag} ->
    {flag_str_list, _} = Enum.unzip(flag)
    @type unquote(type_name(name)) :: list(unquote(atom_typespec_ast(flag_str_list)))
  end)

  Enum.map(vips_immutable_operation_list(), fn name ->
    %{
      desc: desc,
      in_req_spec: in_req_spec,
      in_opt_spec: in_opt_spec,
      out_req_spec: out_req_spec,
      out_opt_spec: out_opt_spec
    } = spec = operation_args_spec(name)

    func_name = function_name(name)

    req_params =
      Enum.map(in_req_spec, fn param ->
        param.param_name
        |> String.to_atom()
        |> Macro.var(__MODULE__)
      end)

    @doc """
    #{prepare_doc(desc, in_req_spec, in_opt_spec, out_req_spec, out_opt_spec)}
    """
    @spec unquote(func_typespec(func_name, in_req_spec, in_opt_spec, out_req_spec, out_opt_spec))
    def unquote(func_name)(unquote_splicing(req_params), optional \\ []) do
      operation_call(unquote(name), unquote(req_params), optional, unquote(Macro.escape(spec)))
    end

    bang_func_name = function_name(String.to_atom(name <> "!"))

    @doc """
    Same as `#{func_name}/#{length(req_params) + 1}`, except it
    returns only the value (not a tuple) and raises on error.
    """
    @spec unquote(
            bang_func_typespec(
              bang_func_name,
              in_req_spec,
              in_opt_spec,
              out_req_spec,
              out_opt_spec
            )
          )
    def unquote(bang_func_name)(unquote_splicing(req_params), optional \\ []) do
      case __MODULE__.unquote(func_name)(unquote_splicing(req_params), optional) do
        :ok -> :ok
        {:ok, result} -> result
        {:error, reason} when is_binary(reason) -> raise Error, message: reason
        {:error, reason} -> raise Error, message: inspect(reason)
      end
    end
  end)
end
