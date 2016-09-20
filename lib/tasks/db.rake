namespace :db do
  desc 'Rebuildify the database and run the seed/tests'
  task rebuildify: :environment do
    return nil unless Rails.env.development?
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:seed'].invoke
  end
end