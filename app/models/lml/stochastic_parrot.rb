# frozen_string_literal: true

module Lml
  class StochasticParrot
    def initialize
      @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"), log_errors: true)
      @logger = Rails.logger
    end

    # rubocop:disable Metrics/MethodLength
    def gist(description)
      @logger.info("Making OpenAI request with description: #{description&.truncate(100)}")
      response = @client.chat(
        parameters: {
          model: "gpt-4.1",
          response_format: { type: "json_object" },
          messages: [
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
          ],
        },
      )
      @logger.info("Received response back from OpenAI: #{response}")
      content = response["choices"].first["message"]["content"]
      JSON.parse(content)["gist_tags"].map(&:downcase)
    end
    # rubocop:enable Metrics/MethodLength
  end
end
