defmodule Kamex.Exceptions do
  @moduledoc false

  defmodule ArityError do
    defexception [:message]
  end

  defmodule UnknownFunctionError do
    defexception [:message]
  end

  defmodule UnknownLocalError do
    defexception [:message]
  end

  defmodule UnbalancedParensError do
    defexception [:message]
  end

  defmodule IllegalTypeError do
    defexception [:message]
  end

  defmodule MathError do
    defexception [:message]
  end

  defmodule ParserError do
    # TODO: enhance to smth link `UnexpectedTokenError` and add line number
    defexception [:message]
  end

  defmodule SyntaxError do
    defexception [:message]
  end
end
