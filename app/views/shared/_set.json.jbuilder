# frozen_string_literal: true

# One set of a gig. Callers order the collection themselves - gigs#show sorts in
# sql, the eager loaded ones sort in memory - this is only the shape.

json.start_time set.start_time
json.start_timestamp set.start_timestamp
json.duration set.duration
json.finish_time set.finish_time
json.finish_timestamp set.finish_timestamp

json.act { json.partial!("shared/act", act: set.act) }
