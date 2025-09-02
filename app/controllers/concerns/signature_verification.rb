# frozen_string_literal: true

# Implemented according to HTTP signatures (Draft 6)
# <https://tools.ietf.org/html/draft-cavage-http-signatures-06>
module SignatureVerification
  extend ActiveSupport::Concern

  include DomainControlHelper

  EXPIRATION_WINDOW_LIMIT = 12.hours
  CLOCK_SKEW_MARGIN       = 1.hour

  def require_account_signature!
    render json: signature_verification_failure_reason, status: signature_verification_failure_code unless signed_request_account
  end

  def require_actor_signature!
    render json: signature_verification_failure_reason, status: signature_verification_failure_code unless signed_request_actor
  end

  def signed_request?
    request.headers['Signature'].present?
  end

  def signature_key_id
    signed_request.key_id
  rescue Mastodon::SignatureVerificationError
    nil
  end

  private

  def signed_request
    @signed_request ||= SignedRequest.new(request) if signed_request?
  end

  def signature_verification_failure_reason
    @signature_verification_failure_reason
  end

  def signature_verification_failure_code
    @signature_verification_failure_code || 401
  end

  def signed_request_account
    signed_request_actor.is_a?(Account) ? signed_request_actor : nil
  end

  def signed_request_actor
    return @signed_request_actor if defined?(@signed_request_actor)

    raise Mastodon::SignatureVerificationError, 'Request not signed' unless signed_request?

    actor = actor_from_key_id

    raise Mastodon::SignatureVerificationError, "Public key not found for key #{signature_key_id}" if actor.nil?

    return (@signed_request_actor = actor) if signed_request.verified?(actor)

    actor = stoplight_wrapper.run { actor_refresh_key!(actor) }

    raise Mastodon::SignatureVerificationError, "Could not refresh public key #{signature_key_id}" if actor.nil?

    return (@signed_request_actor = actor) if signed_request.verified?(actor)

    fail_with! "Verification failed for #{actor.to_log_human_identifier} #{actor.uri}"
  rescue Mastodon::MalformedHeaderError => e
    @signature_verification_failure_code = 400
    fail_with! e.message
  rescue Mastodon::SignatureVerificationError => e
    fail_with! e.message
  rescue *Mastodon::HTTP_CONNECTION_ERRORS => e
    fail_with! "Failed to fetch remote data: #{e.message}"
  rescue Mastodon::UnexpectedResponseError
    fail_with! 'Failed to fetch remote data (got unexpected reply from server)'
  rescue Stoplight::Error::RedLight
    fail_with! 'Fetching attempt skipped because of recent connection failure'
  end

  def fail_with!(message, **options)
    Rails.logger.debug { "Signature verification failed: #{message}" }

    @signature_verification_failure_reason = { error: message }.merge(options)
    @signed_request_actor = nil
  end

<<<<<<< HEAD
  def signature_params
    @signature_params ||= SignatureParser.parse(request.headers['Signature'])
  rescue SignatureParser::ParsingError
    raise SignatureVerificationError, 'Error parsing signature parameters'
  end

  def signature_algorithm
    signature_params.fetch('algorithm', 'hs2019')
  end

  def signed_headers
    signature_params.fetch('headers', signature_algorithm == 'hs2019' ? '(created)' : 'date').downcase.split
  end

  def verify_signature_strength!
    raise SignatureVerificationError, 'Mastodon requires the Date header or (created) pseudo-header to be signed' unless signed_headers.include?('date') || signed_headers.include?('(created)')
    raise SignatureVerificationError, 'Mastodon requires the Digest header or (request-target) pseudo-header to be signed' unless signed_headers.include?(HttpSignatureDraft::REQUEST_TARGET) || signed_headers.include?('digest')
    raise SignatureVerificationError, 'Mastodon requires the Host header to be signed when doing a GET request' if request.get? && !signed_headers.include?('host')
    raise SignatureVerificationError, 'Mastodon requires the Digest header to be signed when doing a POST request' if request.post? && !signed_headers.include?('digest')
  end

  def verify_body_digest!
    return unless signed_headers.include?('digest')
    raise SignatureVerificationError, 'Digest header missing' unless request.headers.key?('Digest')

    digests = request.headers['Digest'].split(',').map { |digest| digest.split('=', 2) }.map { |key, value| [key.downcase, value] }
    sha256  = digests.assoc('sha-256')
    raise SignatureVerificationError, "Mastodon only supports SHA-256 in Digest header. Offered algorithms: #{digests.map(&:first).join(', ')}" if sha256.nil?

    return if body_digest == sha256[1]

    digest_size = begin
      Base64.strict_decode64(sha256[1].strip).length
    rescue ArgumentError
      raise SignatureVerificationError, "Invalid Digest value. The provided Digest value is not a valid base64 string. Given digest: #{sha256[1]}"
    end

    raise SignatureVerificationError, "Invalid Digest value. The provided Digest value is not a SHA-256 digest. Given digest: #{sha256[1]}" if digest_size != 32

    raise SignatureVerificationError, "Invalid Digest value. Computed SHA-256 digest: #{body_digest}; given: #{sha256[1]}"
  end

  def verify_signature(actor, signature, compare_signed_string)
    if actor.keypair.public_key.verify(OpenSSL::Digest.new('SHA256'), signature, compare_signed_string)
      @signed_request_actor = actor
      @signed_request_actor
    end
  rescue OpenSSL::PKey::RSAError
    nil
  end

  def build_signed_string(include_query_string: true)
    signed_headers.map do |signed_header|
      case signed_header
      when HttpSignatureDraft::REQUEST_TARGET
        if include_query_string
          "#{HttpSignatureDraft::REQUEST_TARGET}: #{request.method.downcase} #{request.original_fullpath}"
        else
          # Current versions of Mastodon incorrectly omit the query string from the (request-target) pseudo-header.
          # Therefore, temporarily support such incorrect signatures for compatibility.
          # TODO: remove eventually some time after release of the fixed version
          "#{HttpSignatureDraft::REQUEST_TARGET}: #{request.method.downcase} #{request.path}"
        end
      when '(created)'
        raise SignatureVerificationError, 'Invalid pseudo-header (created) for rsa-sha256' unless signature_algorithm == 'hs2019'
        raise SignatureVerificationError, 'Pseudo-header (created) used but corresponding argument missing' if signature_params['created'].blank?

        "(created): #{signature_params['created']}"
      when '(expires)'
        raise SignatureVerificationError, 'Invalid pseudo-header (expires) for rsa-sha256' unless signature_algorithm == 'hs2019'
        raise SignatureVerificationError, 'Pseudo-header (expires) used but corresponding argument missing' if signature_params['expires'].blank?

        "(expires): #{signature_params['expires']}"
      else
        "#{signed_header}: #{request.headers[to_header_name(signed_header)]}"
      end
    end.join("\n")
  end

  def matches_time_window?
    created_time = nil
    expires_time = nil

    begin
      if signature_algorithm == 'hs2019' && signature_params['created'].present?
        created_time = Time.at(signature_params['created'].to_i).utc
      elsif request.headers['Date'].present?
        created_time = Time.httpdate(request.headers['Date']).utc
      end

      expires_time = Time.at(signature_params['expires'].to_i).utc if signature_params['expires'].present?
    rescue ArgumentError => e
      raise SignatureVerificationError, "Invalid Date header: #{e.message}"
    end

    expires_time ||= created_time + 5.minutes unless created_time.nil?
    expires_time = [expires_time, created_time + EXPIRATION_WINDOW_LIMIT].min unless created_time.nil?

    return false if created_time.present? && created_time > Time.now.utc + CLOCK_SKEW_MARGIN
    return false if expires_time.present? && Time.now.utc > expires_time + CLOCK_SKEW_MARGIN

    true
  end

  def body_digest
    @body_digest ||= Digest::SHA256.base64digest(request_body)
  end

  def to_header_name(name)
    name.split('-').map(&:capitalize).join('-')
  end

  def missing_required_signature_parameters?
    signature_params['keyId'].blank? || signature_params['signature'].blank?
  end

  def actor_from_key_id(key_id)
=======
  def actor_from_key_id
    key_id = signed_request.key_id
>>>>>>> v4.4.3
    domain = key_id.start_with?('acct:') ? key_id.split('@').last : key_id

    if domain_not_allowed?(domain)
      @signature_verification_failure_code = 403
      return
    end

    if key_id.start_with?('acct:')
      stoplight_wrapper.run { ResolveAccountService.new.call(key_id.delete_prefix('acct:'), suppress_errors: false) }
    elsif !ActivityPub::TagManager.instance.local_uri?(key_id)
      account   = ActivityPub::TagManager.instance.uri_to_actor(key_id)
      account ||= stoplight_wrapper.run { ActivityPub::FetchRemoteKeyService.new.call(key_id, suppress_errors: false) }
      account
    end
  rescue Mastodon::PrivateNetworkAddressError => e
    raise Mastodon::SignatureVerificationError, "Requests to private network addresses are disallowed (tried to query #{e.host})"
  rescue Mastodon::HostValidationError, ActivityPub::FetchRemoteActorService::Error, ActivityPub::FetchRemoteKeyService::Error, Webfinger::Error => e
    raise Mastodon::SignatureVerificationError, e.message
  end

  def stoplight_wrapper
    Stoplight("source:#{request.remote_ip}")
      .with_threshold(1)
      .with_cool_off_time(5.minutes.seconds)
      .with_error_handler { |error, handle| error.is_a?(HTTP::Error) || error.is_a?(OpenSSL::SSL::SSLError) ? handle.call(error) : raise(error) }
  end

  def actor_refresh_key!(actor)
    return if actor.local? || !actor.activitypub?
    return actor.refresh! if actor.respond_to?(:refresh!) && actor.possibly_stale?

    ActivityPub::FetchRemoteActorService.new.call(actor.uri, only_key: true, suppress_errors: false)
  rescue Mastodon::PrivateNetworkAddressError => e
    raise Mastodon::SignatureVerificationError, "Requests to private network addresses are disallowed (tried to query #{e.host})"
  rescue Mastodon::HostValidationError, ActivityPub::FetchRemoteActorService::Error, Webfinger::Error => e
    raise Mastodon::SignatureVerificationError, e.message
  end
end
