class Safaricom
#   Creating class method which will be used for authentication.
  def auth
    require 'net/http'
    require 'net/https'
    require 'uri'
#     Making a post request to the mpesa oauth api to get credential that are required when making any kind of api calls
#     that interact with the system.
#     You can use any library here in your language that supports basic auth.
#     For the basic auth the consumer key is the username and the consumer secret the password.
#     Enable ssl in your request.
    uri = URI('https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials')

    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https',:verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth ENV['SAFARICOM_CONSUMER_KEY'], ENV['SAFARICOM_CONSUMER_SECRET']
      response = http.request(request)
      response.body
    end
  end
end
