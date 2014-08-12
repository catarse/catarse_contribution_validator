module CatarseContributionValidator
  class MoIPValidator
    attr_accessor :contribution, :current_details

    def initialize(contribution)
      self.contribution = contribution
    end

    def run
      self.current_details = get_transaction_details

      if self.current_details
        if self.current_details['Autorizacao'].present? && self.current_details['Autorizacao']['Pagamento'].present?
          payment = self.current_details['Autorizacao']['Pagamento']

          if payment.is_a?(Array)
            payment = payment[0]
          end

          puts payment.inspect

          case payment['Status']
          when 'Estornado' || 'Reembolsado' && !self.contribution.refunded? then
            force_adjust_on_contribution
            self.contribution.refund
          when 'Autorizado' || 'Concluido' && !self.contribution.confirmed? then
            force_adjust_on_contribution
            self.contribution.confirm
          when 'BoletoImpresso' || 'EmAnalise' && self.contribution.pending?
            force_adjust_on_contribution
            self.contribution.waiting
          end
        end
      end
    end

    def get_transaction_details
      MoIP::Client.query(self.contribution.payment_token)
    rescue MoIP::WebServerResponseError => e
      puts e.inspect

      transaction_paypal = CatarseContributionValidator::PaypalValidator.new(self.contribution)
      if transaction_paypal.in_paypal?
        transaction_paypal.run_with_search
      else
        force_update_to_moip
      end

      nil
    end

    def force_update_to_moip
      self.contribution.update_attributes({
        payment_method: CatarseContributionValidator::ServiceTypes::MOIP
      })
    end

    def force_adjust_on_contribution
      tax = if self.current_details['Autorizacao']['Pagamento'].is_a?(Array)
              self.current_details['Autorizacao']['Pagamento'][0]['TaxaMoIP'].to_f
            else
              self.current_details['Autorizacao']['Pagamento']['TaxaMoIP'].to_f
            end
      self.contribution.update_attributes({
        payment_method: CatarseContributionValidator::ServiceTypes::MOIP,
        payment_service_fee: tax
      })
    end
  end
end
