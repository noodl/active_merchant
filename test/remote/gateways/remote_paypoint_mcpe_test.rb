require File.dirname(__FILE__) + '/../../test_helper'

class RemotePaypointMcpeTest < Test::Unit::TestCase

  def setup
    @gateway = PaypointMcpeGateway.new(fixtures(:paypoint_mcpe))
    
    @amount = 1000
    @credit_card = credit_card('1234123412341234')
    @declined_card = credit_card('4000300011112220')
    
    @options = { 
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase',
      :email => 'test@example.com',
      :ip => '1.2.3.4'
    }
  end
  
  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal '', response.message
  end

  def test_unsuccessful_purchase
    assert response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    # Urk, should this be declined due to funds rather than a duff card number?
    assert_equal 'The card number given is invalid.', response.message
  end
  
  def test_currency_from_options_gets_used
    # setting the currency happens in private code so we test it by checking for failure at the gateway
    @options[:currency] = 'FOO'
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal 'The currency specified in field strCurrency (FOO) is not supported.', response.message
  end
  
  def test_repeat_payment
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert !response.params["strSecurityToken"].blank?
    
    assert response = @gateway.repeat(@amount, response.authorization, response.params["strSecurityToken"])
    assert_success response
    assert response.message.blank? # we get nil here unlike successful purchases
  end

  # def test_authorize_and_capture
  #   amount = @amount
  #   assert auth = @gateway.authorize(amount, @credit_card, @options)
  #   assert_success auth
  #   assert_equal 'Success', auth.message
  #   assert auth.authorization
  #   assert capture = @gateway.capture(amount, auth.authorization)
  #   assert_success capture
  # end
  # 
  # def test_failed_capture
  #   assert response = @gateway.capture(@amount, '')
  #   assert_failure response
  #   assert_equal 'REPLACE WITH GATEWAY FAILURE MESSAGE', response.message
  # end
end
