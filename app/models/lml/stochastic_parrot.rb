# frozen_string_literal: true

module Lml
  class StochasticParrot
    def initialize
      @client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    end

    def gist(description)
      response = @client.chat(
        parameters: {
          model: "gpt-4o",
          response_format: { type: "json_object" },
          messages: [
            {
              role: "system",
              content: "You are a helpful young research assistant with an interest in live music performances.",
            },
            {
              role: "user",
              content: <<~PROMPT,
                Given the gig described, generate a list of up to four tags that describe music genres
                mentioned or implied. Put the tags in order of relevance. If an act is definitely playing
                the music of another artist and you have confidence of over .85 of this, please add
                the tag "covers".

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
      content = response["choices"].first["message"]["content"]
      JSON.parse(content)["gist_tags"]
    end
  end
end
