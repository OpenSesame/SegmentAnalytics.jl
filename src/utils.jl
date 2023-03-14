using Dates
using TimeZones

function format_timestamp(timestamp::Union{Date,DateTime})
  ZonedDateTime(timestamp, localzone()) |> format_timestamp
end

function format_timestamp(timestamp::ZonedDateTime)
  string(timestamp)
end

function get_with_symbol_or_string(func::Function, dict::Dict, key::Symbol)
  get(dict, key) do
    get(() -> func(), dict, String(key))
  end
end

function get_with_symbol_or_string(dict::Dict, key::Symbol, default)
  get(dict, key) do
    get(dict, String(key), default)
  end
end
