# SegmentAnalytics.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://opensesame.github.io/SegmentAnalytics.jl)

Implementation of segment analytics library inspired by [analytics-ruby](https://github.com/segmentio/analytics-ruby).
 For more information, you can read the Segment[documentation](https://segment.com/docs/connections/sources/catalog/libraries/server/http-api/)

# Installation

```julia-repl
]add SegmentAnalytics
```

# Getting Started

To use SegmentAnalytics, you must initialize the Analytics structure using your write key and custom settings, if necessary. You must then call the required method associated with the Segment API method. Currently, only the `track()` method is available.

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

It's recommended to use Symbol keys when it's possible for performance improvement.
