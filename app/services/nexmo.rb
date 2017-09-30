class Nexmo
  def self.message(message, phone_no)
    RestClient.post 'https://rest.nexmo.com/sms/json', {api_key: ENV['NEXMO_KEY'], api_secret:ENV['NEXMO_SECRET'], from:'Harambee', to: phone_no, text: message}
  end
end
