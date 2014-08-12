module CatarseContributionValidator
  class Validate
    attr_accessor :contribution

    def initialize(contribution)
      @contribution = contribution
    end

    def run
      # PAYPAL ID LIKE: 5CR78372CB53T442P
      # MOIP ID LIKE: 27930867 
      if contribution.payment_id.match(/[a-zA-Z]/)
        if defined?(CatarsePaypalExpress)
          PaypalValidator.new(contribution).run
        else
          puts "Catarse PayPal is not configured..."
        end
      else
        if defined?(CatarseMoip)
          MoIPValidator.new(contribution).run
        else
          puts "Catarse MoIP is not configured..."
        end
      end
      puts "\n++++++++++++++++++++\n"
    end
  end
end
