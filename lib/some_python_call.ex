defmodule SomePythonCall do
  use Export.Python

  def call_python_method do
    # path to our python files
    {:ok, py} = Python.start(python: "/usr/local/bin/python3", python_path: Path.expand("lib/python"))

    # same as above but prettier
    val = py |> Python.call(get_root_hash(<<11,22,33>>), from_file: "get_root_hash")

    # close the Python process
    py |> Python.stop()

    val
  end
end
