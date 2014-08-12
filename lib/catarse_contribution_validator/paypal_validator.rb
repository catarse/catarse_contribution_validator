module CatarseContributionValidator
  class PaypalValidator
    attr_accessor :contribution, :current_details

    def initialize(contribution)
      self.contribution = contribution
    end

    def run
      self.current_details = get_transaction_details

      case self.current_details.params['payment_status']
      when 'Refunded' && !@contribution.refunded? then
        force_adjust_on_contribution
        self.contribution.refund
      when 'Completed' && !@contribution.confirmed? then
        force_adjust_on_contribution
        self.contribution.confirm
      end
    end

    def get_transaction_details
      gateway.transaction_details(@contribution.payment_id)
    end

    def force_adjust_on_contribution
      puts "UPDATING TO PAYPAL"
      self.contribution.update_attributes({
        payment_method: CatarseContributionValidator::ServiceTypes::PAYPAL,
        payment_service_fee: self.current_details.params['fee_amount'].to_f
      })
    end

    protected

    def gateway
      @gateway ||= CatarsePaypalExpress::Gateway.instance
    end
  end
end
