module CatarseContributionValidator
  class Engine < ::Rails::Engine
    isolate_namespace CatarseContributionValidator

    config.to_prepare do
      ::Contribution.send(:include, CatarseContributionValidator::ContributionConcern)
    end
  end
end
