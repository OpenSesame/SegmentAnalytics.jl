# SegmentAnalytics.jl

Documentation for SegmentAnalytics.jl: Julia solutiuon for track analytics using Segment API. For more details check: https://segment.com/docs/api/public-api/


# Installation

```julia-repl
]add SegmentAnalytics
```

# Getting Started

To use SegmentAnalytics, you must initialize the Analytics structure using your write key and custom settings, if necessary, and then call the required method associated with the Segment API method. Currently, only the `track()` method is available.

### Example

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

It's recommended to use Symbol keys when it's possible for performance improvment.