FactoryBot.define do
  factory :releases_commit, class: 'Releases::Commit' do
    commit_hash { 'ae5bdd5b2cb98b75f56411d128e383dbedb7dcc2' }
    association :train, factory: 'releases_train'
    message { 'feat: introduce commit listner' }
    timestamp { '2022-06-21 20:20:21' }
    author_name { 'Jon Doe' }
    author_email { 'jon@doe.com' }
    url { 'https://sample.com' }
  end
end
