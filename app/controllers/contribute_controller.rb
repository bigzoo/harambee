class ContributeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :callback
  def index
    @transaction = Transaction.new
#     Selecting the current harambee from the database that a user is contributing to.
    @harambee = UserHarambee.find(params[:user_harambee_id])
  end

  def transaction
    require 'uri'
    require 'net/http'
#     Creating a new instance of the transaction class. Go to this
#     (https://github.com/bigzoo/harambee/blob/master/db/schema.rb#L18) link to see it's attributes.
#     This instance will be used to store all transaction details (they have been passed in a post request) and it's status.
#     In the bottom of this file is the transaction_params method used here showing the parameters that were passes.
    @transaction = Transaction.new(transaction_params)
#     Save the transaction
    @transaction.save
#     Create a new instance of the safaricom class
    saf = Safaricom.new()
#     Call the auth class method from safaricom.
#     The return value of the auth method is the response body from a call to safaricoms oauth api
#     This response contains an access token that needs to passed in all api calls in an authorization header field.
    response = saf.auth
    response = JSON.parse(response)
    token = response['access_token']
#     The pass key here is obtained from (https://developer.safaricom.co.ke/test_credentials) and must be used
#     when testing the app in the sandbox. This is because Safaricom wants us to use it. No reason why.
    passkey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'
#     The current time in YYYYMMDDHHMMSS format (year-month-date-hour-minutes-seconds)
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
#     The shortcode of the recieving business paybill no.
    shortcode = ENV['BUSSINESS_SHORT_CODE']
#     One of the parameters required by the api is password.
#     This password MUST be a base 64 encoding of the bussiness shortcode, the mpesa provided passkey, and the timestamp
#     You must use a base64 library of your language of choice (that is unless you feel like doing a base 64 calculation).
    encrypted = Base64.strict_encode64(shortcode+passkey+timestamp)
#     With those you are now ready to prepare the request for the api.
#     Prepare the request url with your library of choice for this.
#     For this project I use 'uri'  which is ruby's built in uri builder.
    uri = URI('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest')
    http = Net::HTTP.new(uri.host, uri.port)
#     Enable ssl
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
#     Create the request with your library of choice
#     Again, use your library of chose.
#     For his I use 'net/http',  Ruby's built in http handler
    request = Net::HTTP::Get.new(uri)
#     Set accept type to json
    request["Accept"] = 'application/json'
    request["content-type"] = 'application/json'
#     Set authorization headers. Use the format Bearer + (the token we got from safaricoms oauth response)
    request["authorization"] = 'Bearer '+token+''
#     Also set this. Just because Safaricom says so
    request["cache-control"] = 'no-cache'
#     Prepare the json payload that will be sent along with the request with the request.
    body ={
      'BusinessShortCode': shortcode,
      'Password': encrypted,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
#       The amount you want to receive
      'Amount': @transaction.contributor_amount,
#       The phone no that is paying the money
      'PartyA': @transaction.contributor_phone_no,
#       The business shorcode recieving the money
      'PartyB': shortcode,
#       The phone no that is paying the money
      'PhoneNumber': @transaction.contributor_phone_no,
#       A call back url you want safaricom to post to.
#       In development you can use any local tunneller like ngrok and in production it 
#       will be your applications url
      'CallBackURL': 'https://5b4f28ab.ngrok.io/contribute/callback',
#       The two below are description stuff for the transaction that safaricom stores
      'AccountReference': @transaction.id,
      'TransactionDesc': 'A donation'
    }
#     Make the actual request
    req = RestClient::Request.execute(
    method: :post,
    url:    "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
    payload: body.to_json,
    headers: {:content_type => :json, :accept => :json, :authorization => 'Bearer '+token}
    )
    request = JSON.parse(req)
#     If the response code is 299 then the request was sent successfully.
#     You now wait for the callback to be made by safaricom
    if req.code!='200'
#       Save the id of the transaction that is returned by safaricom with that id
#       When safaricom makes a callback, they will send this is and will obtain the transction with it.
      @transaction.update(merchant_request_id:request['MerchantRequestID'],checkout_request_id:request['CheckoutRequestID'])
      flash[:notice]='Your request has been sent. You will be notified when your transaction is complete by SMS.'
      redirect_to user_harambee_path(@transaction.user_harambee)
    else
      flash[:alert]='Sorry, An error occurred.'
      redirect_to user_harambee_contribute_index_path(@transaction.user_harambee)
    end
  end
  
# This is the callback method that witll be hit by safaricom
  def callback
#     Find the transaction from the db using the checkout id returned by safaricom that we saved earlier
    @transaction = Transaction.find_by_checkout_request_id(params['Body']['stkCallback']['CheckoutRequestID'])
#     Get the descrption of the transaction status
    description = params['Body']['stkCallback']['ResultDesc']
#     If the transaction was successfull do whatever you want to do in your application
    if description=="The service request is processed successfully."
      meta = params['Body']['stkCallback']['CallbackMetadata']['Item']
      @transaction.update(transaction_code:meta[1]["Value"],done:true)
      mes = 'Your donation of '.concat(meta[0]["Value"].to_s) + ' Reciept No. '.concat(meta[1]["Value"].to_s) +' has been recieved by Harambee on '+ meta[3]['Value'].to_s.to_time.to_s + '. Thank You for participating in Harambee.'
      Nexmo.message(mes,@transaction.contributor_phone_no)
      amount = meta[0]["Value"].to_i
      harambee = @transaction.user_harambee
      harambee.raised_amount ||= 0
      rs = harambee.raised_amount
      new_raised = rs.to_i + amount
      harambee.update(raised_amount:new_raised)
      harambee.save()
      if harambee.target_amount<=raised_amount
        transactions = harambee.transactions
        mes = 'Thank you for participating in the '+harambee.name+' contribution. We have reached our target amount.'
        transactions.each do |trans|
          Nexmo.message(mes,trans.contributor_phone_no)
        end
        harambee.update(running:false)
      end
#       Else if it was not do something else like sending an email or a text to the user.
    else
      mes = 'Transaction was not able to complete.'
      Nexmo.message(mes,@transaction.contributor_phone_no)
  end
    # number_to_currency(@harambee.target_amount, options = { unit: "Ksh."})
  end

  private
  def transaction_params
    params.require(:transaction).permit(:user_harambee_id,:contributor_phone_no,:contributor_amount)
  end
end
