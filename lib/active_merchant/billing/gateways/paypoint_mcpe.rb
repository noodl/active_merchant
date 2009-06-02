module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # PayPoint (formerly MetaCharge) Merchant Card Payment Engine
    class PaypointMcpeGateway < Gateway
      URL = 'https://secure.metacharge.com/mcpe/corporate'

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['UK']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :solo, :switch, :master, :american_express, :discover]
      
      self.default_currency = 'GBP'

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.paypoint.net/'

      # The name of the gateway
      self.display_name = 'PayPoint Bank Enterprise'

      def initialize(options = {})
        requires!(options, :intInstID)
        @options = options
        super
      end

      def authorize(money, creditcard, options = {})
        post = {}
        post[:intAuthMode] = 2
        add_amount(post, money, options)
        add_invoice(post, options)
        add_creditcard(post, creditcard)
        add_address(post, creditcard, options)
        add_customer_data(post, options)

        commit('authonly', money, post)
      end

      def purchase(money, creditcard, options = {})
        post = {}
        add_amount(post, money, options)
        add_invoice(post, options)
        add_creditcard(post, creditcard)
        add_address(post, creditcard, options)
        add_customer_data(post, options)

        commit('PAYMENT', money, post)
      end
      
      def repeat(money, transaction_id, security_token, options = {})
        post = {}
        add_amount(post, money, options)
        add_repeat_fields(post, transaction_id, security_token)
        commit('REPEAT', money, post)
      end

      def capture(money, authorization, options = {})
        commit('capture', money, post)
      end

      private

      def add_amount(post, money, options)
        post[:fltAmount] = amount(money)
        post[:strCurrency] = options[:currency] || currency(money)
      end
      
      def add_repeat_fields(post, transaction_id, security_token)
        post[:intTransID] = transaction_id
        post[:strSecurityToken] = security_token or raise "security token must be specified"
      end

      def add_customer_data(post, options)
        post[:strEmail] = options[:email]
        post[:strUserIP] = options[:ip]
      end

      def add_address(post, creditcard, options)
        address = options[:billing_address] || options[:address] || {}
        post[:strAddress] = [address[:address1], address[:address2]].compact.join("\n")
        post[:strCity] = address[:city]
        post[:strState] = address[:state]
        post[:strPostcode] = address[:zip]
        post[:strCountry] = address[:country]
        post[:strTel] = address[:phone]
      end

      def add_invoice(post, options)
        post[:strCartID] = options[:order_id]
        post[:strDesc] = options[:description]
      end

      def add_creditcard(post, creditcard)
        post[:strCardHolder] = creditcard.name
        post[:strCardNumber] = creditcard.number

        # should convert e.g. [8, 2009] to 0809
        post[:strExpiryDate] = "%02d%02d" % [creditcard.expiry_date.month, creditcard.expiry_date.year.to_s[2,2]]

        if requires_start_date_or_issue_number?(creditcard)
          post[:strStartDate] = "%02d%02d" % [creditcard.start_month, creditcard.start_year.to_s[2,2]]
          post[:strIssueNo] = creditcard.issue_number
        end

        post[:intCV2] = creditcard.verification_value
        post[:strCardType] = creditcard.type.upcase
      end

      def commit(action, money, parameters)
        parameters[:intTestMode] = test? ? 1 : 0 # 2 can be used to simulate failed payments
        parameters[:intInstID] = @options[:intInstID]
        parameters[:intAccountID] = @options[:intAccountID] if @options[:intAccountID] # TODO: check that this isn't just for payment requests, in which case it should go elsewhere

        data = ssl_post(URL, post_data(action, parameters))

        response = parse(data)
        Response.new(response[:intStatus] == '1', response[:strMessage], response,
          :authorization => response[:intTransID],
          :test => response[:intTestMode] == '1'
        )
      end

      def post_data(action, parameters = {})
        parameters[:strTransType] = action
        parameters[:fltAPIVersion] = '1.3'
        parameters.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
      end

      def parse(body)
        results = {}
        body.split(/&/).each do |pair|
          key, val = pair.split( /=/ ) # space here to keep TM happy
          results[key.to_sym] = CGI.unescape(val.to_s) # to_s here to stop CGI barfing on nil
        end
        results
      end
    end
  end
end
