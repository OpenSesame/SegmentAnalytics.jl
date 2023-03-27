const DEFAULT_MIN_TIMEOUT_MS = 100
const DEFAULT_MAX_TIMEOUT_MS = 10000
const DEFAULT_MULTIPLIER = 1.5
const DEFAULT_RANDOMIZATION_FACTOR = 0.5

mutable struct BackoffPolicy
  min_timeout_ms::Integer
  max_timeout_ms::Integer
  multiplier::AbstractFloat
  randomization_factor::AbstractFloat
  attempts::Integer
end

function BackoffPolicy(options::Dict)
  BackoffPolicy(
    get(options, :min_timeout_ms, DEFAULT_MIN_TIMEOUT_MS),
    get(options, :max_timeout_ms, DEFAULT_MAX_TIMEOUT_MS),
    get(options, :multiplier, DEFAULT_MULTIPLIER),
    get(options, :randomization_factor, DEFAULT_RANDOMIZATION_FACTOR),
    0
  )
end

function next_interval(policy::BackoffPolicy)
  interval = policy.min_timeout_ms * (policy.multiplier^policy.attempts)
  interval = add_jitter(interval, policy.randomization_factor)

  policy.attempts += 1

  min(interval, policy.max_timeout_ms)
end

function reset!(policy::BackoffPolicy)
  policy.attempts = 0
end

function add_jitter(base, randomization_factor)
  random_number = rand()
  max_deviation = base * randomization_factor
  deviation = random_number * max_deviation

  if random_number < 0.5
    base - deviation
  else
    base + deviation
  end
end
