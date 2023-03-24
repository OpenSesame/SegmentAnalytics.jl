using JSON

const MAX_MESSAGE_BATCH_SIZE = 100
const MAX_MESSAGE_SIZE_IN_BYTES = 32_768 # 32 Kb
const MAX_MESSAGE_BATCH_SIZE_IN_BYTES = 512_000 # 500 Kb

mutable struct MessageBatch
  messages::Vector{Dict}
  max_messages_count::Integer
  json_size::Integer
end

function MessageBatch(max_batch_size::Integer)
  MessageBatch(
    Dict[],
    max_batch_size,
    0
  )
end

function push!(batch::MessageBatch, message::Dict)
  message_json = JSON.json(message)
  message_json_size = sizeof(message_json)

  if message_json_size > MAX_MESSAGE_SIZE_IN_BYTES
    @error "a message exceeded the maximum allowed size"
  else
    Base.push!(batch.messages, message)
    batch.json_size += message_json_size + 1
  end
end

function isfull(batch::MessageBatch)
  length(batch.messages) >= batch.max_messages_count ||
    batch.json_size >= (MAX_MESSAGE_BATCH_SIZE_IN_BYTES - MAX_MESSAGE_SIZE_IN_BYTES)
end

function clear!(batch::MessageBatch)
  deleteat!(batch.messages, 1:length(batch.messages))
  batch.json_size = 0
end

Base.length(batch::MessageBatch) = length(batch.messages)
