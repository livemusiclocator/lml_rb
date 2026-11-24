# frozen_string_literal: true

module Lml
  # lml.live/g/4kZ9qT2m - a link short enough to share, for a gig, venue or act.
  #
  # The code is the first 47 bits of the record's uuid in base62, so there is
  # nothing to store: a code decodes back to a range of uuids, which the primary
  # key index finds directly. 47 because eight base62 characters hold a little
  # under 48 bits. Our uuids come from gen_random_uuid, so those leading bits are
  # as random as any others, and two records sharing a code stays unlikely well
  # past a million of them - ShortLinksController lists both if it happens.
  module ShortLink
    ALPHABET = [*"0".."9", *"A".."Z", *"a".."z"].join.freeze
    LENGTH = 8
    BITS = 47
    KINDS = { "Lml::Gig" => "g", "Lml::Venue" => "v", "Lml::Act" => "a" }.freeze

    def self.url(record)
      "https://lml.live/#{KINDS.fetch(record.class.name)}/#{code(record.id)}"
    end

    def self.code(uuid)
      number = uuid.delete("-")[0, 12].to_i(16) >> (48 - BITS)
      LENGTH.times.map do
        number, digit = number.divmod(ALPHABET.size)
        ALPHABET[digit]
      end.reverse.join
    end

    # The uuids a code could stand for, or nil if it is not a code at all.
    def self.id_range(code)
      number = decode(code)
      return if number.nil? || number >= 2**BITS

      prefix = number << (48 - BITS)
      last = prefix | ((1 << (48 - BITS)) - 1)
      uuid(format("%012x", prefix) + ("0" * 20))..uuid(format("%012x", last) + ("f" * 20))
    end

    def self.decode(code)
      return unless code.to_s.match?(/\A[0-9A-Za-z]{#{LENGTH}}\z/)

      code.each_char.reduce(0) { |sum, char| (sum * ALPHABET.size) + ALPHABET.index(char) }
    end

    def self.uuid(hex)
      hex.unpack("a8a4a4a4a12").join("-")
    end
  end
end
