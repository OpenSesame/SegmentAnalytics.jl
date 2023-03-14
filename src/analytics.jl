using DataStructures
using UUIDs
using Mocking

const MAX_QUEUE_SIZE = 10_000

mutable struct Analytics
  queue::Queue{Dict}
  max_queue_size::Integer
  write_key::String
  worker::Worker
  worker_mutex::ReentrantLock
  worker_task::Union{Nothing,Task}
end

function Analytics(options::Dict)
  queue = Queue{Dict}()
  write_key = get(options, "write_key", nothing)

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

function track(analytics::Analytics, attrs::Dict)
  enqueue(analytics, parse_for_track(attrs))
end

function enqueue(analytics::Analytics, action::Dict)::Bool
  if haskey(action, "messageId")
    action["messageId"] = uuid4() |> string
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
