module CatarseContributionValidator::ContributionConcern
  extend ActiveSupport::Concern

  included do
    scope :collection_to_validate, -> {
      where("(created_at + '1 month') > current_timestamp and payment_id is not null and lower(payment_method) in ('paypal', 'moip')").
      with_state(['pending', 'waiting_confirmation', 'requested_refund', 'deleted']).
      order('created_at desc')
    }
  end
end
