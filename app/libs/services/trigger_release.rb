class Services::TriggerRelease
  include Rails.application.routes.url_helpers

  def self.call(train)
    new(train).call
  end

  attr_reader :train, :starting_time, :train_run

  def initialize(train)
    @train = train
    @starting_time = Time.current
  end

  def call
    return if train.inactive?
    return if train.steps.empty?
    return if train.active_run.present?

    ApplicationRecord.transaction do
      create_run_record
      create_branches
      create_webhooks
      setup_webhook_listeners
      run_first_step
    end
  end

  private

  def create_run_record
    @train_run = train.runs.create(was_run_at: starting_time,
      code_name: Haikunator.haikunate(100),
      scheduled_at: starting_time, # FIXME: remove this column
      branch_name: release_branch,
      release_version: train.version_current,
      status: :on_track)
  end

  def create_branches
    installation.create_branch!(repo, working_branch, new_branch_name)
    message = "Branch #{new_branch_name} is created"
    Automatons::Notify.dispatch!(train:, message:)
  rescue Octokit::UnprocessableEntity
    nil
  end

  # Webhooks are created with the train and we don't need to create webhooks for each train run AKA release
  # This is a fallback mechanism to ensure that webhook gets created if it is not present
  def create_webhooks
    installation.create_repo_webhook!(repo, webhook_url)
  rescue Octokit::UnprocessableEntity
    nil
  end

  def setup_webhook_listeners
    train.commit_listeners.create(branch_name: release_branch)
  end

  def run_first_step
    step = train.steps.first
    step_run = train_run.step_runs.create(step:, scheduled_at: Time.current, status: "on_track")
    step_run.automatons!
  end

  def installation
    @installation ||= train.ci_cd_provider.installation
  end

  def repo
    train.app.config.code_repository_name
  end

  def release_branch
    case train.branching_strategy.to_s
    when "almost_trunk"
      new_branch_name
    when "release_backmerge"
      new_branch_name
    when "parallel_working"
      train.release_branch
    end
  end

  def working_branch
    train.working_branch
  end

  def new_branch_name
    starting_time.strftime("r/#{train.display_name}/%Y-%m-%d")
  end

  def webhook_url
    if Rails.env.development?
      github_events_url(host: ENV["WEBHOOK_HOST_NAME"], train_id: train.id)
    else
      github_events_url(host: ENV["HOST_NAME"], train_id: train.id, protocol: "https")
    end
  end
end