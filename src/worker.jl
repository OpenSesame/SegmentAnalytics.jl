using DataStructures
using Mocking

mutable struct Worker
  queue::Queue{Dict}
  write_key::String
  batch::MessageBatch
  batch_size::Integer
  lock::ReentrantLock
  transport::Transport
  running::Bool
  on_error::Function
end

function Worker(queue::Queue, write_key::String, options::Dict)
  batch_size = get(options, :batch_size, MAX_MESSAGE_BATCH_SIZE)


  Worker(
    queue,
    write_key,
    MessageBatch(batch_size),
    batch_size,
    ReentrantLock(),
    Transport(options),
    true,
    get(options, :on_error, (status, error) -> @error error)
  )
end

function runworker(worker::Worker)
  while worker.running
    isempty(worker.queue) && return

    lock(worker.lock) do
      while !isempty(worker.queue) && !isfull(worker.batch)
        consume_message_from_queue!(worker)
      end

      res = @mock send(worker.transport, worker.write_key, worker.batch)
      res.status != 200 && worker.on_error(res.status, String(res.body))

      lock(worker.lock) do
        clear!(worker.batch)
      end
    end
  end
end

function pause_worker(worker::Worker)
  worker.running = false
end

function consume_message_from_queue!(worker::Worker)
  push!(worker.batch, dequeue!(worker.queue))
end
