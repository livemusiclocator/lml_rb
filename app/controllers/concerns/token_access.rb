# frozen_string_literal: true

# The api subdomain's shared secret gate. TOKENS is a comma separated list of
# tokens handed out to internal callers - there is no per token identity, no
# expiry and no revocation short of a config change, so it only belongs in
# front of things we can live with leaking the moment a token does.
module TokenAccess
  private

  def token_authorized?
    params[:token].present? && tokens.include?(params[:token])
  end

  def authorize_token!
    head :unauthorized unless token_authorized?
  end

  # An unset TOKENS authorizes nobody rather than everybody, so forgetting to
  # configure it fails closed.
  def tokens
    ENV.fetch("TOKENS", "").split(",").map(&:strip).reject(&:empty?)
  end
end
