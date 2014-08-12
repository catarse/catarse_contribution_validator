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
          when 'Cancelado' then
            unless self.contribution.canceled?
              self.contribution.cancel
            end
          when 'Estornado', 'Reembolsado' then
            unless self.contribution.refunded?
              self.contribution.refund
            end
          when 'Autorizado', 'Concluido' then
            unless self.contribution.confirmed?
              self.contribution.confirm
            end
          when 'BoletoImpresso', 'EmAnalise' then
            unless self.contribution.pending?
              self.contribution.waiting
            end
          end

          force_adjust_on_contribution
        end
      end
    end

    def get_transaction_details
      MoIP::Client.query(self.contribution.payment_token)
    rescue MoIP::WebServerResponseError => e
      puts e.inspect
      puts "Verificando PayPal"
      transaction_paypal = CatarseContributionValidator::PaypalValidator.new(self.contribution)
      if transaction_paypal.in_paypal?
        puts 'Existe no PayPal... Executando PayPal Validator'
        transaction_paypal.run_with_search
      else
        puts 'Nao existente no PayPal'
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
