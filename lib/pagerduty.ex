defmodule Pagerduty do
  @moduledoc """
  Pagerduty provides access to version 2 of the Pagerduty API
  """
  use HTTPoison.Base

  @oncall_params [:include, :user_ids, :escalation_policy_ids, :schedule_ids,
                  :since, :until, :earliest]

  def process_url(url) do
    "https://api.pagerduty.com/" <> url
  end

  def process_request_headers(headers) do
    default_headers
    |> Keyword.merge(headers, fn _k, _v, val -> val end)
    |> Enum.into([])
  end

  @doc """
  This describes your account's abilities by feature name, like "teams".
  An ability may be available to your account based on things like your pricing
  plan or account state.

  ## Examples

      iex> Pagerduty.abilities
      {:ok, ["sso", "advanced_reports", "teams", "read_only_users",
             "team_responders", "service_support_hours", "urgencies",
             "manage_schedules", "manage_api_keys", "coordinated_responding",
             "using_alerts_on_any_service", "event_rules",
             "coordinated_responding_preview", "preview_incident_alert_split",
             "features_in_use_preventing_downgrade_to", "feature_to_plan_map"]}
  """
  def abilities do
    with {:ok, %{status_code: 200, body: body}} <- get("abilities"),
         {:ok, resp} <- Poison.decode(body) do
      {:ok, resp["abilities"]}
    else
      {:ok, %{status_code: code}} -> error_for_code(code)
    end
  end

  @doc """
  Test whether your account has a given `ability`.

  Returns `true`, `false`, or `{:error, reason}`

  ## Examples

      iex> Pagerduty.ability?("sso")
      true
  """
  def ability?(ability) do
    with {:ok, %{status_code: code}} <- get("abilities/#{ability}") do
      case code do
        204 -> true
        402 -> false
          _ -> error_for_code(code)
      end
    end
  end

  @doc """
  List the on-call entries during a given time range.

  ## Examples

      iex> Pagerduty.oncalls(user_ids: ["PX6RN71"])
      {:ok, []}
  """
  def oncalls(opts \\ []) do
    query = "time_zone=#{Keyword.get(opts, :time_zone, "UTC")}"
    query =
      Enum.reduce(@oncall_params, query, fn param, query ->
        value = Keyword.get(opts, param)
        case value do
          vs when is_list(vs) ->
            mvs = Enum.join(vs, "&#{param}%5B%5D=")
            "#{query}&#{param}%5B%5D=#{mvs}"
          nil -> query
        end
      end)

    IO.inspect query

    with {:ok, %{status_code: 200, body: body}} <- get("oncalls?#{query}"),
         {:ok, resp} <- Poison.decode(body) do
      {:ok, resp}
    else
      %{status_code: code} -> error_for_code(code)
    end
  end

  defp error_for_code(401), do: {:error, {:bad_credentials, token}}
  defp error_for_code(403), do: {:error, :unauthorized}
  defp error_for_code(404), do: {:error, :not_found}
  defp error_for_code(429), do: {:error, :rate_limit}

  defp default_headers do
    [
      {"Accept", "application/vnd.pagerduty+json;version=2"},
      {"Authorization", "Token token=#{token}"}
    ]
  end

  defp token do
    Application.get_env(:pagerduty, :token)
  end
end
