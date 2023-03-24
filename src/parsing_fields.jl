using Dates
using TimeZones

function parse_for_track(fields::Dict)::Dict
  common = parse_common_fields(fields)

  event = get_with_symbol_or_string(fields, :event, nothing)
  properties = get_with_symbol_or_string(() -> Dict(), fields, :properties)

  isnothing(event) && throw(ArgumentError("event must be given"))
  !isa(properties, Dict) && throw(ArgumentError("properties must be Dict"))

  merge(
    common,
    Dict(
      :type => :track,
      :event => string(event),
      :properties => properties
    )
  )
end

function parse_common_fields(fields::Dict)::Dict
  timestamp = get_with_symbol_or_string(() -> now(localzone()), fields, :timestamp)
  message_id = get_with_symbol_or_string(fields, :message_id, nothing)
  context = get_with_symbol_or_string(() -> Dict(), fields, :context)

  check_user_id!(fields)
  check_timestamp!(timestamp)

  add_context!(context)

  parsed = Dict{Symbol,Any}(
    :context => context,
    :messageId => message_id,
    :timestamp => format_timestamp(timestamp)
  )

  set_parsed_field_if_exist!(fields, parsed, :user_id, :userId)
  set_parsed_field_if_exist!(fields, parsed, :anonymous_id, :anonymousId)
  set_parsed_field_if_exist!(fields, parsed, :integrations, :integrations)

  parsed
end

function set_parsed_field_if_exist!(fields, parsed, src_name, dest_name::Symbol)
  field_value = get_with_symbol_or_string(fields, src_name, nothing)
  if !isnothing(field_value)
    parsed[dest_name] = field_value
  end
end

function check_user_id!(fields::Dict)
  !isnothing(get_with_symbol_or_string(fields, :user_id, nothing)) && return
  !isnothing(get_with_symbol_or_string(fields, :anonymous_id, nothing)) && return

  throw(ArgumentError("Must supply either user_id or anonymous_id"))
end

function check_timestamp!(timestamp)
  !isa(timestamp, DateTime) &&
    !isa(timestamp, ZonedDateTime) &&
    throw(ArgumentError("Timestamp must be a DateTime or ZonedDateTime"))
end

function add_context!(context::Dict)
  context[:library] = (
    name="analytics-julia",
    version=VERSION
  )
end
