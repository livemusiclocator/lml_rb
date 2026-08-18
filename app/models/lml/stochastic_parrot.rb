# frozen_string_literal: true

require "faraday"

module Lml
  class StochasticParrot
    API_KEY_VAR = "OPENAI_API_KEY"

    MODEL = "gpt-4.1"

    def initialize(access_token: ENV.fetch(API_KEY_VAR, nil))
      @access_token = access_token
      # Not under test: the specs that drive the sad paths stub error responses,
      # and ruby-openai cannot tell a stubbed 429 from a real one, so it shouts
      # "You have no credits remaining" into the spec output where it reads as a
      # genuine problem.
      @client = OpenAI::Client.new(access_token: access_token, log_errors: !Rails.env.test?)
      @logger = Rails.logger
    end

    # Returns nil rather than raising when OpenAI cannot answer. Suggesting genre tags enriches a
    # gig, it is not part of saving one, so an unreachable or unwilling OpenAI must not take the
    # upload or the admin edit down with it. A spent credit balance arrives as a 429, which is
    # indistinguishable from a rate limit from here, and either way there is nothing to suggest.
    def gist(description)
      if @access_token.blank?
        @logger.warn("#{API_KEY_VAR} is not set, leaving genre tags unsuggested")
        return
      end

      @logger.info("Making OpenAI request with description: #{description&.truncate(100)}")
      response = chat(description)
      return if response.nil?

      @logger.info("Received response back from OpenAI: #{response}")
      tags(response)
    end

    private

    def chat(description)
      @client.chat(parameters: {
                     model: MODEL,
                     response_format: { type: "json_object" },
                     messages: messages(description),
                   })
    rescue Faraday::Error => e
      @logger.warn("OpenAI request for genre tags failed, leaving them unsuggested: #{e.message}")
      nil
    end

    def tags(response)
      content = response.dig("choices", 0, "message", "content")
      suggested = JSON.parse(content.to_s)["gist_tags"]
      return unless suggested.is_a?(Array)

      suggested.map { |tag| tag.to_s.downcase }
    rescue JSON::ParserError => e
      @logger.warn("OpenAI answered with genre tags that are not JSON, leaving them unsuggested: #{e.message}")
      nil
    end

    # rubocop:disable Metrics/MethodLength
    def messages(description)
      [
        {
          role: "system",
          content: "You are a helpful young research assistant with an interest in live music performances.",
        },
        {
          role: "user",
          content: <<~PROMPT,
            Given the gig described, generate a list of up to four tags that describe music genres mentioned or implied.  Put
            the tags in order of relevance. Only use the tag "covers" if an act is definitely performing
            the music of another artist and you have confidence of over .95 of this. Many descriptions list influences
            of bands but this does not mean a "covers" tag is appropriate. If a band plays ONLY the material of a single band,
            they are a tribute band.

            The first tag should come from this whitelist:

            Rock, Pop, Hip-Hop, R&B, Soul, Jazz, Classical, Electronic, Country, Metal, Folk, Blues, Reggae, Latin, World, Gospel, Dance, Punk, Alternative, Experimental, Indie, Ambient, Hardcore, Industrial, Garage, Trance, House, Techno, Drum and Bass, Dubstep, Funk, Chill, Disco, Opera, Swing, Acoustic, New Wave, DJ, Covers, Tribute.

            Subsequent tags can be more detailed.

            Format JSON output like this:
            {
                "gist_tags": [
                    "tag",
                    "tag2",
                    "tag3"
                ],
            }
            Description: #{description}",
          PROMPT
        },
      ]
    end
    # rubocop:enable Metrics/MethodLength
  end
end
