module CatarseContributionValidator
  class PaypalValidator
    attr_accessor :contribution, :current_details

    def initialize(contribution)
      self.contribution = contribution
    end

    def search
      @search ||= gateway.transaction_search({
        payer: self.contribution.payer_email,
        start_date: self.contribution.created_at
      })
    end

    def get_first_transaction
     transaction = if search.params['PaymentTransactions'].present?
                     search.params['PaymentTransactions'].select do |transaction|
                       ((self.contribution.created_at - transaction['Timestamp'].to_datetime) / 1.hour) < 5.minutes &&
                         self.contribution.created_at.to_date == transaction['Timestamp'].to_date &&
                         self.contribution.value.to_f == transaction['GrossAmoun'].to_f.abs
                     end
                   else
                     nil
                   end
    end

    def in_paypal?
      get_first_transaction.present?
    end

    def run_with_search
      if in_paypal?
        transaction = get_first_transaction
        self.contribution.update_attributes({
          payment_method: CatarseContributionValidator::ServiceTypes::PAYPAL,
          payment_id: transaction['TransactionID']
        })
        self.contribution.reload
        run
      end
    end

    def run
      self.current_details = get_transaction_details

      case self.current_details.params['payment_status']
      when 'Refunded' then
        unless self.contribution.refunded?
          force_adjust_on_contribution
          self.contribution.refund
        end
      when 'Completed' then
        unless self.contribution.confirmed?
          force_adjust_on_contribution
          self.contribution.confirm
        end
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
