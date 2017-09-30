class ContributeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :callback
  def index
    @transaction = Transaction.new
    @harambee = UserHarambee.find(params[:user_harambee_id])
  end

  def transaction
    require 'uri'
    require 'net/http'
    @transaction = Transaction.new(transaction_params)
    @transaction.save
    saf = Safaricom.new()
    response = saf.auth
    response = JSON.parse(response)
    token = response['access_token']
    passkey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
    shortcode = ENV['BUSSINESS_SHORT_CODE']
    encrypted = Base64.strict_encode64(shortcode+passkey+timestamp)
    uri = URI('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = 'application/json'
    request["content-type"] = 'application/json'
    request["authorization"] = 'Bearer '+token+''
    request["cache-control"] = 'no-cache'
    body ={
      'BusinessShortCode': shortcode,
      'Password': encrypted,
      'Timestamp': timestamp,
      'TransactionType': 'CustomerPayBillOnline',
      'Amount': @transaction.contributor_amount,
      'PartyA': @transaction.contributor_phone_no,
      'PartyB': shortcode,
      'PhoneNumber': @transaction.contributor_phone_no,
      'CallBackURL': 'https://5b4f28ab.ngrok.io/contribute/callback',
      'AccountReference': @transaction.id,
      'TransactionDesc': 'A donation'
    }
    req = RestClient::Request.execute(
    method: :post,
    url:    "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
    payload: body.to_json,
    headers: {:content_type => :json, :accept => :json, :authorization => 'Bearer '+token}
    )
    request = JSON.parse(req)
    if req.code!='200'
      @transaction.update(merchant_request_id:request['MerchantRequestID'],checkout_request_id:request['CheckoutRequestID'])
      flash[:notice]='Your request has been sent. You will be notified when your transaction is complete by SMS.'
      redirect_to user_harambee_path(@transaction.user_harambee)
    else
      flash[:alert]='Sorry, An error occurred.'
      redirect_to user_harambee_contribute_index_path(@transaction.user_harambee)
    end
  end

  def callback
    @transaction = Transaction.find_by_checkout_request_id(params['Body']['stkCallback']['CheckoutRequestID'])
    description = params['Body']['stkCallback']['ResultDesc']
    if description=="STK_CBRequest cancelled by user"
      mes = 'Request has been cancelled by the user.'
      Nexmo.message(mes,@transaction.contributor_phone_no)
    elsif description=="The service request is processed successfully."
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
      if harambee.raised_amount>=target_amount
        transactions = harambee.transactions
        mes = 'Thank you for participating in the '+harambee.name+' contribution. We have reached our target amount.'
        transactions.each do |trans|
          Nexmo.message(mes,trans.contributor_phone_no)
        end
        harambee.update(running:false)
      end
    end
    # number_to_currency(@harambee.target_amount, options = { unit: "Ksh."})
  end

  private
  def transaction_params
    params.require(:transaction).permit(:user_harambee_id,:contributor_phone_no,:contributor_amount)
  end
end
