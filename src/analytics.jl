using DataStructures
using UUIDs
using Mocking

const MAX_QUEUE_SIZE = 10_000

"""
    mutable struct Analytics

The type for holding segment configuration and segment state 

    function Analytics(;options...)

Return instance of Analytics initialized with giving options

# Required arguments

- `write_key::String`: Segment write key

# Optional arguments

- `batch_size::Integer`: Max size of batch of messages that will be send to Segment. By default equal to $MAX_MESSAGE_BATCH_SIZE
- `on_error::Function`: Function that will be executed when there is error from segment API

## Arguments for transport configuration

- `host::String`
- `port::Integer`
- `ssl::Bool`
- `headers::Dict`
- `path::String`
- `retries::Integer`
- `backoff_policy::BackoffPolicy`

# Example

```julia
analytics = SegmentAnalytics.Analytics(
  write_key="write_key",
  batch_size=20,
  on_error=(status, error) -> @error "[$status] $error",
  host="customhost.com"
)
```
"""
mutable struct Analytics
  queue::Queue{Dict}
  max_queue_size::Integer
  write_key::String
  worker::Worker
  worker_mutex::ReentrantLock
  worker_task::Union{Nothing,Task}
end

function Analytics(;options...)
  options = Dict(options)

  queue = Queue{Dict}()
  write_key = get(options, :write_key, nothing)

  isnothing(write_key) && throw(ArgumentError("Write key must be initialized"))

  worker = Worker(queue, write_key, options)

  Analytics(
    queue,
    MAX_QUEUE_SIZE,
    write_key,
    worker,
    ReentrantLock(),
    nothing
  )
end

"""
Tracks an event

# Arguments

- `analytics::Analytics`
- `attrs::Dict`: Event payload

## Possible attrs

- `event::String`: Event name
- `properties::Dict`: Event properties (optional)
- `anonymous_id::String`: ID for a user when you don't know who they are yet. (optional but you must provide either an `anonymous_id` or `user_id`)
- `context::Dict`: (optional)
- `integrations::Dict`:  What integrations this event goes to (optional)
- `message_id::String`: ID that uniquely identifies a message across the API. (optional)
- `timestamp::Union{DateTime, ZonedDateTime}`: When the event occurred (optional)
- `user_id::String`: The ID for this user in your database (optional but you must provide either an `anonymous_id` or `user_id`)
- `options::Dict`: Options such as user traits (optional)


# Example

```julia
using SegmentAnalytics

analytics = SegmentAnalytics.Analytics(write_key="write_key")
payload = Dict(
  :event => "Event Name",
  :user_id => "User ID",
  :properties => Dict(:p1 => 1, :p2 => 2),
  :message_id => "custom-message-id"
)

track(analytics, payload)
```
"""
function track(analytics::Analytics, attrs::Dict)
  enqueue(analytics, parse_for_track(attrs))
end

function enqueue(analytics::Analytics, action::Dict)::Bool
  if haskey(action, :messageId)
    action[:messageId] = uuid4() |> string
  end

  if length(analytics.queue) < analytics.max_queue_size
    enqueue!(analytics.queue, action)
    ensure_worker_running(analytics)

    true
  else
    @warn "Queue is full, dropping events. The :max_queue_size configuration parameter can be increased to prevent this from happening."

    false
  end
end

function ensure_worker_running(analytics::Analytics)
  is_worker_running(analytics) && return

  lock(analytics.worker_mutex) do
    is_worker_running(analytics) && return

    analytics.worker_task = @async(@mock(runworker(analytics.worker)))
  end
end

function is_worker_running(analytics::Analytics)
  !isnothing(analytics.worker_task) &&
    istaskstarted(analytics.worker_task) &&
    !istaskdone(analytics.worker_task) &&
    !istaskfailed(analytics.worker_task)
end
