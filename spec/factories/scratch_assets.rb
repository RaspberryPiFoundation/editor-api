FactoryBot.define do
  factory :scratch_asset do
    sequence(:filename) { Random.hex }

    trait :with_file do
      transient { asset_path { file_fixture('test_image_1.png') } }

      after(:build) do |asset, evaluator|
        io = Rails.root.join(evaluator.asset_path).open
        filename = File.basename(evaluator.asset_path)
        content_type = Mime::Type.lookup_by_extension(filename)
        asset.file.attach(io:, filename:, content_type:)
      end
    end
  end
end
