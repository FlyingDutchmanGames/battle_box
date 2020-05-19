defmodule BattleBox.Utilities.HTTP do
  defmodule Response do
    defstruct [:status_code, :headers, body: nil]
  end

  def get(url, headers) do
    %{path_and_query: path_and_query} = parse_url(url)
    {:ok, conn} = open(url)
    stream_ref = :gun.get(conn, path_and_query, headers)
    await_response(conn, stream_ref)
  end

  def post(url, headers, body) do
    %{path_and_query: path_and_query} = parse_url(url)
    {:ok, conn} = open(url)
    stream_ref = :gun.post(conn, path_and_query, headers, body)
    await_response(conn, stream_ref)
  end

  defp open(url) do
    %{transport: transport, host: host, port: port} = parse_url(url)
    {:ok, _conn} = :gun.open(host, port, %{transport: transport})
  end

  defp await_response(conn, stream_ref) do
    response =
      case :gun.await(conn, stream_ref) do
        {:response, :fin, status_code, headers} ->
          {:ok, %Response{status_code: status_code, headers: headers}}

        {:response, :nofin, status_code, headers} ->
          {:ok, body} = :gun.await_body(conn, stream_ref)
          {:ok, %Response{status_code: status_code, headers: headers, body: body}}

        {:error, {:shutdown, :econnrefused}} ->
          {:error, :econnrefused}

        {:error, :timeout} ->
          {:error, :timeout}
      end

    :ok = :gun.shutdown(conn)

    response
  end

  defp parse_url(url) do
    parsed = URI.parse(url)

    transport =
      case parsed do
        %{scheme: "http"} -> :tcp
        %{port: 80} -> :tcp
        %{scheme: "https"} -> :tls
        %{port: 443} -> :tls
      end

    path_and_query =
      case parsed do
        %{path: nil, query: nil} -> "/"
        %{path: path, query: nil} -> path
        %{path: nil, query: query} -> "?" <> query
        %{path: path, query: query} -> path <> "?" <> query
      end

    %{
      transport: transport,
      host: :binary.bin_to_list(parsed.host),
      path_and_query: :binary.bin_to_list(path_and_query),
      port: parsed.port
    }
  end
end
