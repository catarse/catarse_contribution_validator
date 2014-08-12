# desc "Explaining what the task does"
# task :catarse_contribution_validator do
#   # Task goes here
# end
namespace :catarse_contribution_validor do
  task validate: :environment do
    Contribution.collection_to_validate.each do |contribution|
      CatarseContributionValidator::Validate.new(contribution).run
    end
  end
end
