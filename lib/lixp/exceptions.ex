defmodule Lixp.Exceptions do
  @moduledoc false

  defmodule ArityError do
    defexception [:message]
  end

  defmodule UnknownFunctionError do
    defexception [:message]
  end

  defmodule UnbalancedParensError do
    defexception [:message]
  end
end
