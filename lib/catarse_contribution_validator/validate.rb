module CatarseContributionValidator
  class Validate
    attr_accessor :contribution

    def initialize(contribution)
      puts "Cheking #{contribution.id} with state #{contribution.state} and payment_method #{contribution.payment_method}"
      self.contribution = contribution
    end

    def run
      # PAYPAL ID LIKE: 5CR78372CB53T442P
      # MOIP ID LIKE: 27930867 
      if self.contribution.payment_id.match(/[a-zA-Z]/)
        if defined?(CatarsePaypalExpress)
          PaypalValidator.new(self.contribution).run
        else
          puts "Catarse PayPal is not configured..."
        end
      else
        if defined?(CatarseMoip)
          MoIPValidator.new(self.contribution).run
        else
          puts "Catarse MoIP is not configured..."
        end
      end

      puts "to => state #{contribution.state} and payment_method #{contribution.payment_method}"
      puts "\n\n++++++++++++++++++++\n\n"
    end
  end
end
