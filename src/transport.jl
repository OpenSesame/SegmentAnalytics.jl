using JSON
using HTTP
using Dates
using TimeZones
using Mocking

const DEFAULT_HOST = "api.segment.io"
const DEFAULT_PORT = 443
const DEFAULT_PATH = "/v1/import"
const DEFAULT_USE_SSL = true
const DEFAULT_HEADERS = Dict(
  "Accept" => "application/json",
  "Content-Type" => "application/json",
  "User-Agent" => "analytics-julia/$(VERSION)"
)
const DEFAULT_RETRIES = 10
const DEFAULT_READ_TIMEOUT = 8
const DEFAULT_OPEN_TIMEOUT = 4

struct Transport
  host::String
  port::Integer
  use_ssl::Bool
  headers::Dict
  path::String
  retries::Integer
  backoff_policy::BackoffPolicy
end

struct TransportException <: Exception
  status
  error
end

function Transport(options::Dict)
  Transport(
    get(options, "host", DEFAULT_HOST),
    get(options, "port", DEFAULT_PORT),
    get(options, "ssl", DEFAULT_USE_SSL),
    get(options, "headers", DEFAULT_HEADERS),
    get(options, "path", DEFAULT_PATH),
    get(options, "retries", DEFAULT_RETRIES),
    get(options, "backoff_policy", BackoffPolicy(options))
  )
end

function send(transport::Transport, write_key::String, batch::MessageBatch)
  @debug "Sending request for $(length(batch)) items"

  last_response, exception = retry_with_backoff(transport.backoff_policy, transport.retries) do
    status_code, body = send_request(transport, write_key, batch)
    error = get(JSON.parse(body), "error", nothing)
    should_retry = should_retry_request(status_code, body)

    @debug "Response status code: $(status_code)"
    !isnothing(error) && @debug "Response error: $(error)"

    [HTTP.Response(status_code; body=error), should_retry]
  end

  reset!(transport.backoff_policy)

  if !isnothing(exception)
    @error exception.error

    HTTP.Response(exception.status; body=exception.error)
  else
    last_response
  end
end

function should_retry_request(status_code, body)
  if status_code >= 500
    true # Server error
  elseif status_code == 429
    true # Rate limited
  elseif status_code >= 400
    @error body

    false # Client error. Do not retry, but log
  else
    false
  end
end

function retry_with_backoff(func::Function, backoff_policy::BackoffPolicy, retries_remaining)
  result, caught_exception = nothing, nothing
  should_retry = false

  try
    result, should_retry = func()
    should_retry || return [result, nothing]
  catch exception
    caught_exception = if isa(exception, HTTP.StatusError)
      TransportException(exception.status, String(exception.response.body))
    else
      TransportException(500, exception)
    end

    should_retry = true
  end

  if should_retry && retries_remaining > 1
    @debug "Retrying request, $(retries_remaining) retries left"
    sleep(next_interval(backoff_policy) / 1000.0)
    retry_with_backoff(func, backoff_policy, retries_remaining - 1)
  else
    [result, caught_exception]
  end
end

function send_request(transport::Transport, write_key, batch)
  payload = JSON.json(
    Dict(
      "sentAt" => localzone() |> now |> format_timestamp,
      "batch" => batch.messages
    )
  )

  response = @mock HTTP.post(
    path(transport, write_key);
    body=payload,
    headers=transport.headers,
    require_ssl_verification=transport.use_ssl,
    connect_timeout=DEFAULT_OPEN_TIMEOUT,
    readtimeout=DEFAULT_READ_TIMEOUT
  )

  [response.status, String(response.body)]
end

function path(transport::Transport, write_key)
  "https://$(write_key):@$(transport.host):$(transport.port)$(transport.path)"
end
