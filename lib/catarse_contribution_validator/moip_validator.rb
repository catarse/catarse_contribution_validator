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

          puts self.current_details.inspect
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
    rescue Exception => e
      puts e.inspect
      nil
    end

    def force_adjust_on_contribution
      self.contribution.update_attributes({
        payment_method: CatarseContributionValidator::ServiceTypes::MOIP,
        payment_service_fee: self.current_details['Autorizacao']['Pagamento']['TaxaMoIP'].to_f
      })
    end
  end
end
