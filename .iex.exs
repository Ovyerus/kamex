Application.put_env(:elixir, :ansi_enabled, true)
IEx.configure(inspect: [charlists: :as_lists])
import Kamex.Interpreter
