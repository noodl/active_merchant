require File.dirname(__FILE__) + '/../../test_helper'

class PaypointMcpeTest < Test::Unit::TestCase
  def setup
    @gateway = PaypointMcpeGateway.new(
                 :intInstID => 123456
               )

    @credit_card = credit_card
    @amount = 1000
    
    @options = { 
      :order_id => '654321',
      :billing_address => address,
      :description => 'description of goods'
    }
  end
  
  def test_required_parameters_on_init
    assert_raise(ArgumentError) { ActiveMerchant::Billing::PaypointMcpeGateway.new }
  end
  
  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of Response, response
    assert_success response
    
    # Replace with authorization number from the successful response
    assert_equal '12345678', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end
  
  def test_repeat_payment
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of Response, response
    assert_success response
    
    # Replace with authorization number from the successful response
    assert_equal '12345678', response.authorization
    assert response.test?
    
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    assert response = @gateway.repeat(@amount, response.authorization, response.params["strSecurityToken"])
    assert_success response
  end

  private
  
  def successful_purchase_response
    [
      ['intTestMode', '1'],
      ['intInstID', '123456'],
      ['strCartID', '654321'],
      ['strDesc', 'description+of+goods'],
      ['fltAmount', '10.00'],
      ['strCurrency', 'GBP'],
      ['strCardHolder', 'Joe+Bloggs'],
      ['strPostcode', 'BA12BU'],
      ['strEmail', 'test@paypoint.net'],
      ['strCardType', 'VISA'],
      ['strCountry', 'GB'],
      ['intTransID', '12345678'],
      ['intAccountID', '123456'],
      ['intStatus', '1'],
      ['intTime', '1070332412'],
      ['strSecurityToken', 'abc']
    ].map { |pair| pair.join('=') }.join('&')
  end
  
  # The exact details here aren't important as the test only looks at intStatus
  def failed_purchase_response
    [
      ['intTestMode', '1'],
      ['intInstID', '123456'],
      ['strCartID', '654321'],
      ['strDesc', 'description+of+goods'],
      ['fltAmount', '10.00'],
      ['strCurrency', 'GBP'],
      ['strCardHolder', 'Joe+Bloggs'],
      ['strPostcode', 'BA12BU'],
      ['strEmail', 'test@paypoint.net'],
      ['strCardType', 'VISA'],
      ['strCountry', 'GB'],
      ['intTransID', '12345678'],
      ['intAccountID', '123456'],
      ['intStatus', '0'],
      ['intTime', '1070332412'],
    ].map { |pair| pair.join('=') }.join('&')
  end
end
